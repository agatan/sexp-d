module sexp;

import std.variant;
import std.format;
import std.algorithm;
import std.string;
import std.conv;

abstract class Sexp
{
public:
    abstract override @safe pure string toString() const;
}

final class Atom : Sexp
{
public:
    @safe pure nothrow @nogc this(string v)
    {
        this.val = v;
    }

    @safe pure nothrow this(T)(T v) if (__traits(compiles, v.toString))
    {
        this.val = v.toString;
    }

    @safe pure nothrow this(T)(T v) if (__traits(compiles, to!string(v)))
    {
        this.val = v.to!string;
    }

    override @safe pure string toString() const
    {
        return val;
    }

private:
    string val;
}

final class List : Sexp
{
public:
    @safe pure nothrow this(Sexp[] elems...)
    {
        this.elems = elems;
    }

    override @safe pure string toString() const
    {
        return format("(%(%s %))", this.elems);
    }

private:
    Sexp[] elems;
}

unittest
{
    scope s = new Atom("string");
    assert(s.toString == "string");

    scope s2 = new List(new Atom("+"), new Atom("1"), new Atom("2"));
    assert(s2.toString == "(+ 1 2)");
}

private class SexpParser
{
public:
    @safe nothrow pure this(string src)
    {
        this.src = src;
    }

private:
    string src;

    @safe pure void skipWs()
    {
        if (this.src == "") return;
        src = src.stripLeft;
    }

    unittest
    {
        auto p = new SexpParser("   abc");
        p.skipWs;
        assert(p.src == "abc");
    }

    @safe pure Sexp parseAtom()
    {
        this.skipWs;
        immutable idx = src.indexOfAny(" )");
        if (idx == -1) {
            auto ret = new Atom(this.src);
            this.src = "";
            return ret;
        }
        auto ret = new Atom(this.src[0..idx]);
        this.src = this.src[idx..$];
        this.skipWs;
        return ret;
    }

    unittest
    {
        auto p = new SexpParser("abc   def");
        auto res = p.parseAtom;
        assert(res.toString == "abc");
        assert(p.src == "def");

        p = new SexpParser("abc)");
        res = p.parseAtom;
        assert(res.toString == "abc");
        assert(p.src == ")");
    }

    @safe pure Sexp parse()
    {
        this.skipWs;
        if (src[0] == '(') {
            src = src[1..$];
            Sexp[] elems = [];
            while (src[0] != ')') {
                elems ~= this.parse;
            }
            src = src[1..$];
            this.skipWs;
            return new List(elems);
        } else {
            return this.parseAtom;
        }
    }

    unittest
    {
        auto p = new SexpParser("(+ 1 2)");
        auto res = p.parse;
        assert(res.toString == "(+ 1 2)");

        p = new SexpParser("(+ 1 (- 3 2))");
        res = p.parse;
        assert(res.toString == "(+ 1 (- 3 2))");
    }
}

@safe pure Sexp parse(in string src)
{
    return new SexpParser(src).parse;
}

@safe pure Sexp cons(T)(Sexp s, T v) if (__traits(compiles, v.to!string) || __traits(compiles, v.toString))
{
    if (cast(Atom)s) throw new Error("");
    Sexp newelem = new Atom(v);
    auto elms = [newelem] ~ (cast(List)s).elems;
    return new List(elms);
}

unittest
{
    Sexp s = new List(new Atom("x"), new Atom("y"), new Atom("z"));
    assert(s.cons(2).toString == "(2 x y z)");

    try {
        s = new Atom(1);
        s.cons(2);
        assert(false);
    } catch {
        // should be reach here.
    }
}
