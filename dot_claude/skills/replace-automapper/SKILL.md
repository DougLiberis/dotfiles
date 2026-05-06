---
name: replace-automapper
description: Replace AutoMapper with hand-written mapping extension methods in a .NET codebase
argument-hint: "[project-path-or-layer]"
---

# Replace AutoMapper with Hand-Written Mappers

You are a senior .NET engineer. Replace AutoMapper with explicit, hand-written mapping extension methods in the target codebase. This improves debuggability, eliminates runtime reflection, and makes mapping logic visible in code review.

## Input

The user argument is: $ARGUMENTS

This can be:
- A path to a specific project or layer (e.g., `src/MyApp.Database`)
- A specific AutoMapper profile class name (e.g., `DbMappingProfile`)
- Empty (scan the entire solution for AutoMapper usage)

## Strategy

This is a multi-phase refactor. Complete each phase fully before moving to the next. Run the build after each phase to catch issues early.

---

## Phase 1: Discovery — Understand What Exists

### 1a. Find all AutoMapper packages

Search `*.csproj` files for AutoMapper package references:
- `AutoMapper`
- `AutoMapper.Extensions.Microsoft.DependencyInjection`
- `AutoMapper.Extensions.EnumMapping`
- Any other `AutoMapper.*` packages

Record which projects reference them.

### 1b. Find all mapping profiles

Search for classes that inherit from `AutoMapper.Profile`. These contain the mapping configuration that must be replicated. For each profile, catalogue:
- Every `CreateMap<TSource, TDestination>()` call
- Custom member mappings (`.ForMember()`, `.ForAllMembers()`)
- Ignored members (`.ForMember(dest => dest.X, opt => opt.Ignore())`)
- Custom constructors (`.ConstructUsing()`)
- Value transformations (`.ConvertUsing()`, `.MapFrom()`)
- Reverse maps (`.ReverseMap()`)
- Conditional mappings (`.Condition()`, `.PreCondition()`)

### 1c. Find all mapping call sites

Search for all usages of the mapper:
- `IMapper` injection and `.Map<>()` calls
- Static mapper wrappers (e.g., `DbMapper.Map<TSource, TDest>()`, `entity.Map<TSource, TDest>()`)
- `_mapper.Map()`, `_mapper.Map<T>()`, `_mapper.Map(source, destination)` (in-place mutation)
- `ProjectTo<T>()` in EF Core queries (these need special attention — see Phase 3)

### 1d. Find the DI registration

Search for `AddAutoMapper()` or `services.AddAutoMapper()` in `Startup.cs`, `Program.cs`, or `ServiceCollectionExtensions`. This registration will be removed in Phase 5.

### 1e. Report findings

Present the user with a summary before writing any code:
- Number of profiles, total `CreateMap` pairs, call sites
- Any complex mappings that need special attention (flattening, type converters, `ProjectTo`)
- Proposed file structure for the replacement

Wait for user confirmation before proceeding.

---

## Phase 2: Write Hand-Written Mappers

### Mapping file structure

Create a single static mapper class per layer/project that had a profile. Name it based on the mapping direction:
- `EntityMapper.cs` — for database entity <-> domain model mappings
- `DtoMapper.cs` — for API DTO <-> domain model mappings
- `ContractMapper.cs` — for external contract <-> domain model mappings

Place each in a `Mapping/` folder in the same project as the profile it replaces.

### Extension method pattern

Use extension methods — one `ToDomain()` and one `ToEntity()` (or `ToDto()`, `ToContract()`) per type pair:

```csharp
public static class EntityMapper
{
    // --- TypeName ---

    public static DomainModel ToDomain(this SomeEntity entity)
        => new(/* constructor args mapped from entity */)
        {
            // Property initializers for anything not in the constructor
            Id = entity.Id,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };

    public static SomeEntity ToEntity(this DomainModel domain)
        => new()
        {
            // All properties explicitly assigned
            Id = domain.Id,
            // ... etc
        };
}
```

### Mapping rules to follow

1. **Replicate the AutoMapper profile exactly** — do not "improve" mappings during the migration. Match the original behaviour field-by-field. Improvements come in a separate PR.

2. **Constructor arguments first, then init properties** — use record/class constructors where the target type requires it, then set remaining settable properties via object initializer.

3. **Preserve `Ignore()` semantics** — if AutoMapper was configured to ignore a property, the hand-written mapper should simply not set it (rely on the default value). Add a comment noting the deliberate omission if the reason isn't obvious.

4. **Preserve `ForMember` transformations** — if AutoMapper applied a transformation (e.g., `.ToUpper()`, null coalescing), replicate it exactly. Use `ToUpperInvariant()` instead of `ToUpper()` for culture-safe string normalization — but only if the original also used `ToUpper()`/`ToUpperInvariant()` (do not add normalization that didn't exist).

5. **In-place mutation mappers** — if AutoMapper's `.Map(source, destination)` overload was used (mutating an existing object), create a `void MapTo(this TSource source, TDest dest)` extension method. Document why it exists and how it differs from the factory `ToEntity()` method:
   ```csharp
   /// <summary>
   /// Updates an existing <see cref="TargetEntity"/> in place from the domain model.
   /// Unlike <see cref="ToEntity"/>, this method deliberately does NOT set Id,
   /// CreatedAt, or UpdatedAt — the caller manages those.
   /// </summary>
   public static void MapTo(this DomainModel source, TargetEntity dest)
   {
       dest.Property1 = source.Property1;
       // ...
   }
   ```

6. **Nested object mapping** — call the appropriate `ToDomain()`/`ToEntity()` extension on nested objects rather than inlining the mapping. This keeps each mapper self-contained.

7. **Null handling** — match AutoMapper's default: if the source is null, either return null (for reference types) or throw. For nullable nested objects, use `?.ToDomain()` or similar. If the original profile used `AllowNull` or custom null substitution, replicate that.

8. **Collection mapping** — replace `_mapper.Map<List<TDest>>(sourceList)` with `sourceList.Select(x => x.ToDomain()).ToList()`. No need for a dedicated collection extension method.

9. **JSONB / serialized fields** — if the AutoMapper profile serialized/deserialized JSON (common for EF Core JSONB columns), replicate the exact same `JsonSerializer.Serialize/Deserialize` calls with the same options.

---

## Phase 3: Handle EF Core `ProjectTo<T>()` (if present)

`ProjectTo<T>()` translates AutoMapper mappings into SQL via EF Core expression trees. Hand-written mappers cannot replace this directly.

**Options (present to user):**
- **Option A (recommended):** Replace `ProjectTo<T>()` with `.Select(e => e.ToDomain())` and materialize first with `.ToListAsync()`. This changes the query from server-side to client-side projection — acceptable for small result sets.
- **Option B:** For large result sets, write an explicit `.Select()` expression that EF Core can translate to SQL, then map the result.
- **Option C:** Keep `ProjectTo` for specific hot paths by retaining AutoMapper only for that query (not recommended — defeats the purpose).

**Important:** `.Select(e => e.ToDomain())` in an EF Core `IQueryable` may or may not translate to SQL depending on the provider and complexity. If the method contains logic EF cannot translate, materialize first: `.ToListAsync()` then `.Select(e => e.ToDomain())`.

---

## Phase 4: Update Repository / Base Class Patterns

If the codebase uses a generic base repository that previously depended on AutoMapper:

### Replace generic Map calls with abstract methods

Change the base repository from using a generic mapper to requiring each concrete repository to provide its own mapping:

```csharp
// Before (AutoMapper-dependent base)
protected TModel ToModel(TEntity entity) => entity.Map<TEntity, TModel>();
protected TEntity ToEntity(TModel model) => model.Map<TModel, TEntity>();

// After (abstract methods)
protected abstract TModel MapToDomain(TEntity entity);
protected abstract TEntity MapToEntity(TModel model);
```

### Each concrete repository implements the abstract methods

```csharp
public class FooRepository : BaseRepository<FooEntity, MyDbContext, FooDomain>
{
    protected override FooDomain MapToDomain(FooEntity entity) => entity.ToDomain();
    protected override FooEntity MapToEntity(FooDomain model) => model.ToEntity();
}
```

### Backward compatibility (temporary)

If many call sites use the old `ToModel()`/`ToEntity()` helper names, you can keep thin wrappers that delegate to the abstract methods during migration. Remove these wrappers once all call sites are updated — they should not survive as permanent API.

### Update LINQ queries in repositories

Replace all inline `.Map<TSource, TDest>()` calls in LINQ chains:
```csharp
// Before
.Select(e => e.Map<FooEntity, FooDomain>())

// After
.Select(e => e.ToDomain())
```

---

## Phase 5: Remove AutoMapper

### Remove DI registration
Delete `services.AddAutoMapper()` or `builder.Services.AddAutoMapper()` from startup/DI configuration.

### Remove profile classes
Delete all `Profile`-derived classes (e.g., `DbMappingProfile.cs`, `ApplicationMappingProfile.cs`).

### Remove static mapper wrappers
Delete generic static mapper classes (e.g., `DbMapper.cs`, `ApplicationMapper.cs`) that wrapped `IMapper`.

### Remove package references
Remove from all `*.csproj` files:
```xml
<PackageReference Include="AutoMapper" ... />
<PackageReference Include="AutoMapper.Extensions.Microsoft.DependencyInjection" ... />
```

### Remove unused usings
Clean up `using AutoMapper;` from all files. The build will flag any missed references.

### Build and fix
Run `dotnet build` — any remaining references to the deleted types will surface as compile errors. Fix each one.

---

## Phase 6: Update Tests

### Update existing mapping tests

- Remove `IMapper` instantiation and `MapperConfiguration` setup from test constructors
- Replace `_mapper.Map<TSource, TDest>(source)` with `source.ToDomain()` / `source.ToEntity()`
- Remove `AutoMapper` prefix from test method names if present
- Ensure round-trip tests still pass (entity -> domain -> entity should preserve values)

### Add property coverage tests (recommended)

Create a reflection-based test that ensures every settable property on each mapping destination type is either explicitly mapped or deliberately excluded. This prevents silent data loss when new properties are added:

```csharp
public class EntityMapperPropertyCoverageTests
{
    public static TheoryData<Type, HashSet<string>, string> ToDomainMappings => new()
    {
        {
            typeof(DomainFoo),
            new HashSet<string> { "Prop1", "Prop2", "Id", "CreatedAt", "UpdatedAt" },
            "FooEntity -> DomainFoo"
        },
        // ... one entry per mapping pair
    };

    [Theory]
    [MemberData(nameof(ToDomainMappings))]
    public void ToDomain_AllProperties_AreMappedOrExcluded(
        Type destinationType, HashSet<string> accountedFor, string description)
    {
        var settable = destinationType
            .GetProperties(BindingFlags.Public | BindingFlags.Instance)
            .Where(p => p.CanWrite && p.GetSetMethod(nonPublic: false) != null)
            .Select(p => p.Name)
            .ToHashSet();

        var unaccounted = settable.Except(accountedFor).ToList();
        var stale = accountedFor.Except(settable).ToList();

        unaccounted.Should().BeEmpty(
            $"mapping '{description}': unmapped properties on {destinationType.Name}");
        stale.Should().BeEmpty(
            $"mapping '{description}': stale entries no longer on {destinationType.Name}");
    }
}
```

Create matching `ToEntityMappings` data for the reverse direction.

---

## Phase 7: Verify and Clean Up

1. **Build:** `dotnet build` — must be zero errors, zero warnings related to removed types
2. **Test:** `dotnet test` — all existing tests must pass
3. **Search:** Grep the entire solution for `AutoMapper`, `IMapper`, `Profile`, `CreateMap`, `ForMember`, `ProjectTo` — there should be zero hits in `*.cs` and `*.csproj` files (CLAUDE.md and docs may still mention it and should be updated)
4. **Update documentation:** If the project has CLAUDE.md files or similar, update references from "AutoMapper-backed" to "hand-written extension methods"

---

## Principles

- **No behaviour changes** — this is a pure refactor. The mapped values must be identical before and after.
- **One commit per phase** if the change is large, or a single commit if the codebase is small.
- **Build after every phase** — do not accumulate unverified changes.
- **Preserve call-site semantics** — if the original code mapped in a LINQ `.Select()`, keep it in the `.Select()`. If it mapped after materialization, keep it after.
- **Culture-safe normalization** — use `ToUpperInvariant()` / `ToLowerInvariant()` instead of `ToUpper()` / `ToLower()` for any string normalization in mappers.
