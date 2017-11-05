# SqlQuery
Fast, lightweight and strongly typed library to query stored procedures. It offers easy and simple to use strongly typed API, supports TVPs as well as multiple result sets.

# Setup in 30 seconds

1. Install-Package SqlQuery
2. Open SqlProcs.tt and setup connection string, ie.
```csharp
	sqlQuery.ConnectionString = "Server=.;Database=MyDatabaseName;Trusted_Connection=True;";
```
3. Add your Stored Procedure name and save file, to collect result sets T4 will execute stored proc in transaction and roll it back
```csharp
	.Add(new SqlProc("dbo.GetAllMakesAndModels").ResultSets("Make", "Model"))
```
4. Setup is now done, you can now query stored proc:
```csharp
	var result = Sql.DbRepository.DboGetAllMakesAndModels();
	result.Makes[0].MakeName; // contains your first result set
	result.Models[0].ModelName // contains your second result set
```

Run & voilla, you just queried database.

# Configuration options

Code below declares dbo.GetAllMakesAndModels stored proc and names result sets "Make" and "Model" respectively. Naming result sets is optional, T4 will create collections named Set1, Set2, Set3 and so on.

```csharp
sqlQuery.Add(new SqlProc("dbo.GetAllMakesAndModels").ResultSets("Make", "Model"));
```

All parameters are discovered automatically with classes generated for TVP (with strongly typed constructor - in case database definition changes your code will not compile and highlight all touch points to fix), for example to add models declare this in SqlProcs.tt:

```csharp
sqlQuery.Add(new SqlProc("dbo.AddModels"));
```

Then in your CS file use:

```csharp
var models = new List<AddModelsTvp>
{
	new AddModelsTvp("RS5", 4000, true), // strongly typed constructor
	new AddModelsTvp("Q7", 3000, true)
};
Sql.DbRepository.DboAddModels(1, models); // strongly typed proc parameters
```

And we added 2 new Audi models.

## Passing parameters while querying for result set

Some procs may require specific parameter(s) to work and return result sets, you can specify them using SetParameterValue, they are output "as specified":

```csharp
sqlQuery.Add(new SqlProc("dbo.AddModels").SetParameterValue("makeId", "1"));
```

## All returned properties are non nullable

By default all properties on result classes are non nullable to make it easier to consume data. Any nullable column will be replaced with default(myType). If you want to return nullable items declare them explicitly by adding semicolon after result set and listing column names:

```csharp
sqlQuery.Add(new SqlProc("dbo.GetAllMakesAndModels").ResultSets("Make", "Model;EngineCapacityCc;IsManufactured"));
```

Now EngineCapacityCc and IsManufactured in "Model" result set are nullable int? and bool? respectively:

```csharp
var result = await Sql.DbRepository.DboGetAllMakesAndModelsAsync();
var hasEngineCc = result.Models.First().EngineCapacityCc.HasValue ? "Has engine capacity" : "doesn't";
```

## Changing connection string and Dependency Injection

To change connection string use static method below or integrate into Dependency Injection:

```csharp
Sql.ConnectionString = "Server=MyAddress;Database=MyDatabaseName;Trusted_Connection=True;";
```

Recommended approach for bigger applications is to integrate with your IoC container, sample for NInject:

```csharp
public class MyModule : NinjectModule
{
	public override void Load()
	{
		Bind<ISqlExecuteConnectionManager>().To<SqlConnectionManager>();
		Bind<ISqlExecute>().To<SqlExecute>();
		Bind<IDbRepository>().To<DbRepository>();
	}
}
```

You need to implement SqlConnectionManager, easiest option is to inherit from generated SqlExecuteConnectionManager class:

```csharp
public class SqlConnectionManager : SqlExecuteConnectionManager
{
	public override string GetConnectionString()
	{
		return "Server=MyAddress;Database=MyDatabaseName;Trusted_Connection=True;";
	}
}
```

If you want more control then you can implement interface instead:

```csharp
public class SqlConnectionManager : ISqlExecuteConnectionManager
{
	public string GetConnectionString() => System.Configuration.ConfigurationManager.ConnectionStrings["MainDatabase"].ConnectionString;

	public SqlConnection GetSqlConnection() => new SqlConnection(GetConnectionString());
}
```

## Async queries

In real life you'll likely need Async queries, DbRepository has Async versions for each proc returning Task<T> (remember to check IsFaulted and inspect Exception in continuations):

```csharp
static async Task QueryAsync()
{
	var result = await Sql.DbRepository.DboGetAllMakesAndModelsAsync();

	result.Makes.ForEach(make =>
		Console.WriteLine(string.Join("\n",
				result.Models
				.Where(model => model.MakeId == make.MakeId)
				.Select(model => $"{make.MakeName} {model.ModelName}"))));
}
```

## Extending generated objects

Sometimes you need extra property or method to aggregate or interpret results. This can be done thanks to partial classes:

```csharp
public partial class DboGetAllMakesAndModelsResult
{
	public partial class Model
	{
		public bool IsEngineOver2000cc => this.EngineCapacityCc > 2000;
	}
}
```

# Dealing with problems

Should you encounter a problem try to open SqlQuery.tt and select "Current Document" in "Error list". This will show only issues related to SqlQuery instead of flooding window with large numbers of errors caused by side effects.

Remember TT will only regenerate if you save SqlProcs.tt. Engine is included in SqlQuery.tt, files are split so you won't lose config when upgrading library.