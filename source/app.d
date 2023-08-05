module implements;

void main()
{
}

///
bool implements(T, Interface)()
{
	bool result = true;
	static foreach (member; __traits(allMembers, Interface))
	{
		static if (__traits(hasMember, T, member))
		{
			bool subresult = false;
			foreach (overload; __traits(getOverloads, T, member))
			{
				if (parametersMatch!(overload, __traits(getMember, Interface, member)))
				{
					if (hasAttributes!(overload, __traits(getMember, Interface, member)))
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
	interface Bar
	{
		int baz(in int value) @safe;
	}

	interface Pepis
	{
		string baz(string v);
	}

	struct Foo
	{
		string baz(string v) @safe
		{
			return v;
		}

		int baz(int v) @nogc
		{
			return v;
		}
	}

	static assert(!implements!(Foo, Bar));
	static assert(implements!(Foo, Pepis));
}

private bool hasAttributes(alias Implementation, alias Interface)()
{
	enum interfaceAttributes = __traits(getFunctionAttributes, Interface);
	enum implementationAttributes = __traits(getFunctionAttributes, Implementation);

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
