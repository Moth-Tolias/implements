///
module implements;

///
bool implements(Implementation, Interface)()
{
	bool result = true;
	static foreach (member; __traits(allMembers, Interface))
	{
		static if (__traits(hasMember, Implementation, member))
		{
			bool subresult = false;
			alias interfaceMember = __traits(getMember, Interface, member);
			foreach (overload; __traits(getOverloads, Implementation, member))
			{
				if (parametersMatch!(overload, interfaceMember))
				{
					if (hasAttributes!(overload, interfaceMember))
					{
						subresult |= true;
					}
				}
			}

			result &= subresult;
		}
		else
		{
			result = false;
		}
	}

	return result;
}

///
@nogc nothrow pure @safe unittest
{
	interface Foo
	{
		int f(in int value) @safe;
	}

	interface Bar
	{
		string f(string v);
	}

	interface Baz
	{
		int x();
	}

	struct S
	{
		string f(string v) @safe;
		int f(int _) @nogc;
		int f(int _, int _) @safe;
	}

	static assert(!implements!(S, Foo));
	static assert(implements!(S, Bar));
	static assert(!implements!(S, Baz));
}

private bool hasAttributes(alias Implementation, alias Interface)()
{
	immutable interfaceAttributes = __traits(getFunctionAttributes, Interface);
	immutable implementationAttributes = __traits(getFunctionAttributes, Implementation);

	bool result = true;
	foreach (interfaceAttribute; interfaceAttributes)
	{
		import std.algorithm.comparison: among;

		switch (interfaceAttribute)
		{
		case "@safe":
			result &= ("@safe".among(implementationAttributes) > 0 ||
					"@trusted".among(implementationAttributes) > 0);
			break;
		case "@system":
			//always matches, noop
			break;
		default:
			result &= interfaceAttribute.among(implementationAttributes) > 0;
			break;
		}
	}

	return result;
}

@nogc nothrow pure @safe unittest
{
	void foo() @safe;
	void bar();
	void baz() @nogc nothrow pure @safe;

	static assert(!hasAttributes!(bar, foo));
	static assert(hasAttributes!(foo, bar));
	static assert(hasAttributes!(baz, foo));
	static assert(hasAttributes!(baz, bar));
	static assert(!hasAttributes!(bar, baz));
	static assert(!hasAttributes!(foo, baz));
}

private bool parametersMatch(alias Implementation, alias Interface)()
{
	bool result = true;

	import std.traits: Parameters;

	if (Parameters!(Implementation).length == Parameters!(Interface).length)
	{
		foreach (index, InterfaceType; Parameters!(Interface))
		{
			import std.traits: isAssignable;

			result &= isAssignable!(InterfaceType, Parameters!(Implementation)[index]);
			foreach (storageClass; __traits(getParameterStorageClasses, Interface, index))
			{
				import std.algorithm.comparison: among;

				result &= storageClass.among(__traits(getParameterStorageClasses,
						Implementation, index)) > 0;
			}
		}

		return result;
	}
	else
	{
		return false;
	}
}

@nogc nothrow pure @safe unittest
{
	void foo(in int _);
	void bar(int _);

	static assert(parametersMatch!(foo, bar));
	static assert(!parametersMatch!(bar, foo));
}
