import std;

void main()
{
}

bool implements(T, Interface)()
{
	bool result = true;
	static foreach (member; __traits(allMembers, Interface))
	{
		static if (__traits(hasMember, T, member))
		{
			bool subresult = false;
			static foreach (overload; __traits(getOverloads, T, member))
			{
				static if (parametersMatch!(overload, __traits(getMember, Interface, member)))
				{
					static if (hasAttributes!(overload, __traits(getMember, Interface, member)))
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
			return 69;
		}
	}

	static assert(!implements!(Foo, Bar));
	static assert(implements!(Foo, Pepis));
}

bool hasAttributes(alias Implementation, alias Interface)()
{
	enum interfaceAttributes = __traits(getFunctionAttributes, Interface);
	enum implementationAttributes = __traits(getFunctionAttributes, Implementation);

	bool result = true;
	static foreach (interfaceAttribute; interfaceAttributes)
	{
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

bool parametersMatch(alias Implementation, alias Interface)()
{
	bool result = true;
	static if (Parameters!(Implementation).length == Parameters!(Interface).length)
	{

		static foreach (index, InterfaceType; Parameters!(Interface))
		{
			result &= isAssignable!(InterfaceType, Parameters!(Implementation)[index]);
			static foreach (storageClass; __traits(getParameterStorageClasses, Interface, index))
			{
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
	void foof(in int _);
	void barf(int _);
	static assert(parametersMatch!(foof, barf));

	void baz1(int _);
	void baz2(in int _);

	static assert(!parametersMatch!(baz1, baz2));
}
