import std.stdio;

void main()
{
	writeln("Edit source/app.d to start your project.");
}

import std;

void main()
{
    Foo foo;
    writeln(foo.baz(420));
}

interface Bar
{
    int baz(in int value) @safe;
}

struct Foo
{
    static assert(implements!(Foo, Bar));

    int baz(int v) @trusted
    {
        return cast(int)&v + 69;
    }
}

bool implements(T, Interface)()
{
    static foreach (member; __traits(allMembers, Interface))
    {
        bool hasMember = __traits(hasMember, T, member);
        if (!hasMember || (hasMember && !hasAttributes!(T, Interface, member)))
        {
            return false;
        }
    }

    return true;
}

bool hasAttributes(T, Interface, string member)()
{
    auto interfaceAttributes =  __traits(getFunctionAttributes, __traits(getMember, Interface, member));
    auto objectAttributes = __traits(getFunctionAttributes, __traits(getMember, T, member));
    
    static foreach(attribute; interfaceAttributes)
    {
    	
    }
    //return __traits(getFunctionAttributes, __traits(getMember, Interface, member)).among(
      //      __traits(getFunctionAttributes, __traits(getMember, T, member))) > 0;
    return false;
}

