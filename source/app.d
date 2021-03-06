module app;

import std.stdio;
import std.algorithm;
import std.array;
import vibe.d;
import jsonschema: validateJson;
import jsonpointer: jsonPointer;

void executeTest(Json schema, Json test)
{
	Json description = test["description"];
	assert(description.type == Json.Type.string);
	writeln("    " ~ description.get!string);

	Json valid = test["valid"];
	assert(valid.type == Json.Type.bool_);

	Json data = test["data"];
	assert(data.type != Json.Type.undefined);

	bool testResult = validateJson(schema, data);

	assert(testResult == valid.get!bool);
}

void executeTestSuite(Json testSuite)
{
	Json description = testSuite["description"];
	assert(description.type == Json.Type.string);
	writeln("  " ~ description.get!string);

	Json schema = testSuite["schema"];
	assert(schema.type == Json.Type.object);
	Json tests = testSuite["tests"];
	assert(tests.type == Json.Type.array);

	foreach (size_t i, Json t; tests)
	{
		executeTest(schema, t);
	}
}

void executeTestFile(Json testFile)
{
	assert(testFile.type == Json.Type.array);

	foreach (size_t i, Json t; testFile)
	{
		assert(t.type == Json.Type.object);
		executeTestSuite(t);
	}
}

void main()
{
	string testFolder = "JSON-Schema-Test-Suite/tests/draft4";

	string[] excluded = ["definitions.json",
	"ref.json", 
	"refRemote.json",
	"maxLength.json", "minLength.json",
	"bignum.json", "zeroTerminatedFloats.json"];

	string[] files = std.file.dirEntries(testFolder, "*.json", std.file.SpanMode.depth)
		.map!(a => a.name)
		.filter!(a => !excluded.canFind(std.path.baseName(a)))
		.array;

	foreach(f; files)
	{
		writeln(std.path.baseName(f));
		Json j = readFileUTF8(f).parseJsonString;
		executeTestFile(j);
	}
}
