module judy.judyl;

import core.exception;
import std.array;
import std.range;
import std.string;

import judy.external;

struct JudyLArray(ElementType)
{
    private:
        void* array_;

        struct JudyLEntry(ElementType)
        {
            public:
                const size_t index;
                const ElementType value;

                this(const size_t index, const ref ElementType value)
                {
                    this.index = index;
                    this.value = value;
                }

                string toString()
                {
                    return format("%s: (%s) '%s'", index, ElementType.stringof, value);
                }
        }
        alias Entry = JudyLEntry!ElementType;


    public:
        ~this()
        {
            JudyLFreeArray(&array_, NO_ERROR);
        }

        @property bool empty() const
        {
            return count == 0;
        }

        /* Returns number of elements in the Judy array */
        @property size_t count() const
        {
            return JudyLCount(array_, 0, -1, NO_ERROR);
        }



        @property Entry front() const
        {
            size_t index = 0;
            ElementType value;

            if (first(index, value))
            {
                return Entry(index, value);
            }
            throw new RangeError();
        }

        void popFront()
        {
            size_t index = 0;
            if (first(index))
            {
                remove(index);
            }
            else
            {
                throw new RangeError();
            }
        }



        @property Entry back() const
        {
            size_t index = -1;
            ElementType value;

            if (last(index, value))
            {
                return Entry(index, value);
            }
            throw new RangeError();
        }

        void popBack()
        {
            size_t index = -1;
            if (last(index))
            {
                remove(index);
            }
            else
            {
                throw new RangeError();
            }
        }


        auto opSlice()
        {
            return JudyLArrayRange!ElementType(array_);
        }

        auto opSlice(const size_t start, const size_t end)
        {
            return JudyLArrayRange!ElementType(array_, start, end);
        }

        size_t opDollar() const
        {
            if (empty)
            {
                throw new RangeError();
            }
            return back.index;
        }
        
        
        
        ref ElementType opIndex(const size_t index) const
        {
            auto element = cast(ElementType**)JudyLGet(array_, index, NO_ERROR);
            if (element is null)
            {
                throw new RangeError();
            }
            return **element;
        }



        void opIndexAssign(ref ElementType value, const size_t index)
        {
            add(index, value);
        }

        void add(const size_t index, ref ElementType value)
        {
            auto element = cast(ElementType**)JudyLIns(&array_, index, NO_ERROR);
            if (element is null)
            {
                throw new RangeError();
            }
            *element = &value;
        }

        bool remove(const size_t index)
        {
            return JudyLDel(&array_, index, NO_ERROR) == 1;
        }

        bool at(const size_t index, out ElementType value) const
        {
            auto element = cast(ElementType**)JudyLGet(array_, index, NO_ERROR);
            if (element is null)
            {
                return false;
            }
            value = **element;
            return true;
        }

        bool has(const size_t index) const
        {
            return JudyLGet(array_, index, NO_ERROR) !is null;
        }


        /* Search functions for finding elements */
        bool first(ref size_t index, out ElementType found) const
        {
            auto value = cast(ElementType**)JudyLFirst(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool first(ref size_t index) const
        {
            return JudyLFirst(array_, &index, NO_ERROR) !is null;
        }

        size_t first() const
        {
            return front.index;
        }

        bool next(ref size_t index, out ElementType found) const
        {
            auto value = cast(ElementType**)JudyLNext(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool next(ref size_t index) const
        {
            return JudyLNext(array_, &index, NO_ERROR) !is null;
        }

        bool prev(ref size_t index, out ElementType found) const
        {
            auto value = cast(ElementType**)JudyLPrev(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool prev(ref size_t index) const
        {
            return JudyLPrev(array_, &index, NO_ERROR) !is null;
        }

        bool last(ref size_t index, out ElementType found) const
        {
            auto value = cast(ElementType**)JudyLLast(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool last(ref size_t index) const
        {
            return JudyLLast(array_, &index, NO_ERROR) !is null;
        }

        size_t last() const
        {
            return back.index;
        }


        /* Search functions for finding empty */
        bool firstEmpty(ref size_t index) const
        {
            return JudyLFirstEmpty(array_, &index, NO_ERROR) == 1;
        }

        bool nextEmpty(ref size_t index) const
        {
            return JudyLNextEmpty(array_, &index, NO_ERROR) == 1;
        }

        bool prevEmpty(ref size_t index) const
        {
            return JudyLPrevEmpty(array_, &index, NO_ERROR) == 1;
        }

        bool lastEmpty(ref size_t index) const
        {
            return JudyLLastEmpty(array_, &index, NO_ERROR) == 1;
        }

        @property size_t memUsed() const
        {
            return JudyLMemUsed(array_);
        }

        @property size_t memActive() const
        {
            return JudyLMemActive(array_);
        }



        /* Iteration struct, allows fast read only iteration of the underlying Judy array */
        struct JudyLArrayRange(ElementType)
        {
            private:
                ElementType* frontPtr_;
                ElementType* backPtr_;
                size_t leftBound_;
                size_t rightBound_;
                size_t firstIndex_;
                size_t lastIndex_;
                const void* array_;

            public:
                this(const void* array)
                {
                    this(array, 0UL, -1UL);
                }

                this (const void* array, const size_t firstIndex, const size_t lastIndex)
                {
                    array_ = array;
                    leftBound_ = firstIndex_ = firstIndex;
                    rightBound_ = lastIndex_ = lastIndex;

                    auto element = cast(ElementType**)JudyLFirst(array, &firstIndex_, NO_ERROR);
                    if (element !is null)
                    {
                        frontPtr_ = *element;
                    }

                    element = cast(ElementType**)JudyLLast(array, &lastIndex_, NO_ERROR);
                    if (element !is null)
                    {
                        backPtr_ = *element;
                    }
                }

                @property bool empty() const
                {
                    return frontPtr_ is null;
                }

                @property Entry front() const
                {
                    if (frontPtr_ is null)
                    {
                        throw new RangeError();
                    }
                    return Entry(firstIndex_, *frontPtr_);
                }

                void popFront()
                {
                    auto element = cast(ElementType**)JudyLNext(array_, &firstIndex_, NO_ERROR);

                    if (element is null)
                    {
                        frontPtr_ = null;
                        backPtr_ = null;
                    }
                    else
                    {
                        frontPtr_ = *element;
                    }
                }

                @property Entry back() const
                {
                    if (backPtr_ is null)
                    {
                        throw new RangeError();
                    }
                    return Entry(lastIndex_, *backPtr_);
                }

                void popBack()
                {
                    auto element = cast(ElementType**)JudyLPrev(array_, &lastIndex_, NO_ERROR);
                    if (element is null)
                    {
                        frontPtr_ = null;
                        backPtr_ = null;
                    }
                    else
                    {
                        backPtr_ = *element;
                    }
                }

                ref ElementType opIndex(size_t index) const
                {
                    if (index < leftBound_ || index > rightBound_)
                    {
                        throw new RangeError();
                    }

                    auto element = cast(ElementType**)JudyLGet(array_, index, NO_ERROR);

                    if (element is null)
                    {
                        throw new RangeError();
                    }

                    return **element;
                }

                @property JudyLArrayRange!ElementType save()
                {
                    return this;
                }

                @property auto count() const
                {
                    return JudyLCount(array_, firstIndex_, lastIndex_, NO_ERROR);
                }
        }
}


version(unittest)
{
    import std.conv;
    import std.exception;
    import std.stdio;
}

unittest
{
    writeln("[JudyL UnitTest] - count");

    auto array = JudyLArray!string();

    string hello = "hello";

    assert(array.count == 0, "Array starting count is 0");

    array[0] = hello;
    assert(array.count == 1, "Array count updated");

    array[1] = hello;
    assert(array.count == 2, "Array count updated");

    array.remove(0);
    assert(array.count == 1, "Array count updated");

    array.remove(1);
    assert(array.count == 0, "Array count updated");
}

unittest
{
    writeln("[JudyL UnitTest] - empty");

    auto array = JudyLArray!string();

    string hello = "hello";

    assert(array.empty, "Array starts empty");

    array[0] = hello;
    assert(!array.empty, "Array not empty");

    array.add(1, hello);
    assert(!array.empty, "Array not empty");

    array.remove(0);
    array.remove(1);
    assert(array.empty, "Array now empty");
}

unittest
{
    writeln("[JudyL UnitTest] - has");

    auto array = JudyLArray!string();

    string hello = "hello";

    assert(!array.has(0), "Array doesn't have element");
    assert(!array.has(1), "Array doesn't have element");

    array[0] = hello;

    assert(array.has(0), "Array has element");
    assert(!array.has(1), "Array doesn't have element");

    array[1] = hello;

    assert(array.has(0), "Array has element");
    assert(array.has(1), "Array has element");
}

unittest
{
    writeln("[JudyL UnitTest] - at");

    auto array = JudyLArray!string();

    string hello = "hello";
    string world = "world";

    string value;

    assert(!array.at(0, value), "Array doesn't have element");
    assert(!array.at(1, value), "Array doesn't have element");

    array[0] = hello;
    assert(array.at(0, value), "Array has element");
    assert(value == hello);

    array[1] = world;
    assert(array.at(1, value), "Array has element");
    assert(value == world);
}

unittest
{
    writeln("[JudyL UnitTest] - add");

    auto array = JudyLArray!string();

    string hello = "hello";
    string world = "world";

    array.add(0, hello);
    assert(array[0] == hello, "Array has element");

    array.add(1,  world);
    assert(array[1] == world, "Array has element");

    array.add(0,  world);
    assert(array[0] == world, "Element updated");
}

unittest
{
    writeln("[JudyL UnitTest] - opIndexAssign");

    auto array = JudyLArray!string();

    string hello = "hello";
    string world = "world";

    array[0] = hello;
    assert(array[0] == hello, "Array has element");

    array[1] = world;
    assert(array[1] == world, "Array has element");

    array[0] = world;
    assert(array[0] == world, "Element updated");
}

unittest
{
    writeln("[JudyL UnitTest] - opIndex");

    auto array = JudyLArray!string();

    string hello = "hello";
    string world = "world";

    assertThrown!RangeError(array[0], "Array doesn't have element");
    assertThrown!RangeError(array[1], "Array doesn't have element");

    array[0] = hello;
    assert(array[0] == hello, "Array has element");

    array[1] = world;
    assert(array[1] == world, "Array has element");
}

unittest
{
    writeln("[JudyL UnitTest] - remove");

    auto array = JudyLArray!string();

    assert(!array.remove(0), "Array doesn't have element");

    string hello = "hello";
    array[0] = hello;
    assert(array.remove(0), "Array had element");

    assert(!array.has(0), "Element removed");
}

unittest
{
    writeln("[JudyL UnitTest] - forward iteration");

    auto array = JudyLArray!string();

    auto testrange = iota(100, 1000, 10);

    // Alocate storage for the string values on the stack
    string[int] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    foreach(str; array)
    {
        assert(false, "Empty array");
    }

    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    auto j = 0;
    foreach(ref str; array)
    {
        assert(str.index == testrange[j]);
        assert(str.value == array[testrange[j++]]);
    }
    assert(array.count == testrange.length, "Forward iteration leaves data intact");
}

unittest
{
    writeln("[JudyL UnitTest] - front and back");

    auto array = JudyLArray!string();

    auto testrange = iota(100, 1000, 10);

    // Alocate storage for the string values on the stack
    string[int] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    // Verify front and back
    assert(array.front.index == 100, "Correct front");
    assert(array.front.value == "100", "Correct front");
    assert(array.back.index == 990, "Correct back");
    assert(array.back.value == "990", "Correct back");


    // Remove front
    array.remove(100);
    assert(array.front.index == 110, "Front updated");
    assert(array.front.value == "110", "Front updated");
    assert(array.back.index == 990, "Back unchanged");
    assert(array.back.value == "990", "Back unchanged");

    // Remove back
    array.remove(990);
    assert(array.front.index == 110, "Front unchanged");
    assert(array.front.value == "110", "Front unchanged");
    assert(array.back.index == 980, "Back updated");
    assert(array.back.value == "980", "Back updated");

    // Remove middle
    array.remove(550);
    assert(array.front.index == 110, "Front unchanged");
    assert(array.front.value == "110", "Front unchanged");
    assert(array.back.index == 980, "Back updated");
    assert(array.back.value == "980", "Back updated");
}

unittest
{
    writeln("[JudyL UnitTest] - popFront and popBack");

    auto array = JudyLArray!string();

    auto testrange = iota(0, 10);

    // Alocate storage for the string values on the stack
    string[int] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    auto first = array.first();

    auto second = first;
    array.next(second);

    auto last = array.last();
    
    auto second_last = last;
    array.prev(second_last);

    array.popFront();
    assert(!array.has(first), "Front removed");
    assert(array.front.index == second, "Front updated");
    assert(array.has(last), "Back unchanged");

    array.popBack();
    assert(!array.has(last), "Back removed");
    assert(array.back.index == second_last, "Back updated");
    assert(array.has(second), "Front unchanged");
}

unittest
{
    writeln("[JudyL UnitTest] - free memory");

    JudyLArray!string* ptr;

    {
        auto array = JudyLArray!string();

        assert(array.memUsed == 0, "No memory used on empty array");
        assert(array.memActive == 0, "No memory active on empty array");

        auto testrange = iota(0, 100);

        // Alocate storage for the string values on the stack
        string[int] strings = assocArray(
            zip(
                testrange,
                map!(a => to!string(a))(testrange).array
            )
        );

        // Insert some elements
        foreach(i; testrange)
        {
            array[i] = strings[i];
        }

        assert(array.count == 100, "Count updated");
        assert(array.memUsed > 0, "Memory used");
        assert(array.memActive > 0, "Memory active");

        ptr = &array;
    }

    assert(ptr.count == 0, "Count cleared");
    assert(ptr.memUsed == 0, "Memory reclaimed");
    assert(ptr.memActive == 0, "Memory reclaimed");
}


unittest
{
    writeln("[JudyL UnitTest] - opSlice");

    auto array = JudyLArray!string();

    auto testrange = iota(0UL, 100UL);

    // Alocate storage for the string values on the stack
    string[size_t] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Test empty
    foreach(str; array[])
    {
        assert(false, "empty array");
    }

    // Test one element
    array[1000] = strings[0];
    size_t j = 0;
    foreach(ref str; array[])
    {
        assert(j++ == 0, "Called once");
        assert(str.index == 1000, "Index preserved");
        assert(str.value == strings[0]);
    }
    array.remove(1000);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    assert(array.count == array[].count, "Array and slice count the same");

    j = 0;
    foreach(ref str; array[])
    {
        assert(str.index == testrange[j]);
        assert(str.value == strings[j++], "Forward range iteration");
    }

    // backwards iteration
    j = testrange[$-1];
    foreach(ref str; retro(array[]))
    {
        assert(str.index == testrange[j]);
        assert(str.value == strings[j--], "Retrograde range iteration");
    }

    auto slice = array[];
    foreach(i; testrange)
    {
        assert(slice[i] == array[i], "Slice random access");
    }

    assertThrown!RangeError(slice[200], "Out of bounds");

    string hello = "hello";
    string world = "world";

    array[50] = hello;
    array[10000] = world;

    assert(slice[50] == hello, "Array mutation reflected in slice");
    assert(slice[10000] == world, "Array insertion reflected in slice");
}

unittest
{
    writeln("[JudyL UnitTest] - opSlice[x..y]");

    auto array = JudyLArray!string();

    auto testrange = iota(0, 100UL);

    // Alocate storage for the string values on the stack
    string[size_t] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Test empty
    foreach(str; array[1..2])
    {
        assert(false, "empty array");
    }

    // Test one element
    array[2] = strings[0];
    size_t j = 0;
    foreach(ref str; array[0..5])
    {
        assert(j == 0, "Called once");
        assert(str.index == 2);
        assert(str.value == strings[0]);
    }
    array.remove(2);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    j = 20;
    foreach(ref str; array[20..30])
    {
        assert(str.index == j);
        assert(str.value == strings[j++], "Indexed slice");
    }

    j = 20;
    foreach(ref str; array[20..500])
    {
        assert(str.index == j);
        assert(str.value == strings[j++], "Indexed slice beyond population");
    }

    j = 90;
    foreach(ref str; array[90..$])
    {
        assert(str.index == j);
        assert(str.value == strings[j++], "OpDollar slice");
    }

    j = 20;
    foreach(ref str; retro(array[10..20]))
    {
        assert(str.index == j);
        assert(str.value == strings[j--], "Retrograde slice");
    }

    auto slice = array[50..$];
    foreach(i; 50..100)
    {
        assert(slice[i] == array[i], "Random access");
    }

    assertThrown!RangeError(array[10..20][9], "Out of bounds");
    assertThrown!RangeError(array[10..20][21], "Out of bounds");

    string hello = "hello";
    string world = "world";

    array[67] = hello;
    array[200] = world;

    assert(slice[67] == hello, "Array mutation reflected in slice");
}

unittest
{
    writeln("[JudyL UnitTest] - opDollar");

    auto array = JudyLArray!string();

    auto testrange = iota(0, 100UL, 5);

    // Alocate storage for the string values on the stack
    string[size_t] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Test empty
    assertThrown!RangeError(array[$]);

    // Test one element
    array[0] = strings[0];
    array[$] = strings[5];
    assert(array[0] == strings[5]);
    array.remove(0);

    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    array[$] = strings[0];

    assert(array[95] == strings[0], "opDollar is last index");

    string hello = "hello";
    array[size_t.max] = hello;

    auto slice = array[95..$];
    assert(slice.count == 2);
    assert(slice[95] == strings[0]);
    assert(slice[size_t.max] == hello);
}


unittest
{
    writeln("[JudyL UnitTest] - find in empty array");

    auto array = JudyLArray!string();

    string found;
    size_t index = 0;
    assert(!array.first(index, found), "Empty array");
    assert(!array.first(index), "Empty array");
    assertThrown!RangeError(array.first(), "Empty array");

    index = 0;
    assert(!array.next(index, found), "Empty array");
    assert(!array.next(index), "Empty array");

    index = -1;
    assert(!array.prev(index, found), "Empty array");
    assert(!array.prev(index), "Empty array");

    index = -1;
    assert(!array.last(index, found), "Empty array");
    assert(!array.last(index), "Empty array");
    assertThrown!RangeError(array.last(), "Empty array");
}

unittest
{
    writeln("[JudyL UnitTest] - find with single element at start");

    auto array = JudyLArray!string();

    string hello = "hello";
    array[0] = hello;

    string found;



    size_t index = 0;
    assert(array.first(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 0;
    assert(array.first(index));
    assert(index == 0);
    assert(array.first() == 0);

    index = 0;
    assert(!array.next(index, found));

    index = 0;
    assert(!array.next(index));

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(!array.prev(index));

    index = 0;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 0;
    assert(array.last(index));
    assert(index == 0);
    assert(array.last() == 0);



    index = 1;
    assert(!array.first(index, found));
    assert(!array.first(index));

    index = 1;
    assert(!array.next(index, found));
    assert(!array.next(index));

    index = 1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 1;
    assert(array.prev(index));
    assert(index == 0);

    index = 1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 1;
    assert(array.last(index));
    assert(index == 0);



    index = -1;
    assert(!array.first(index, found));

    index = -1;
    assert(!array.first(index));

    index = -1;
    assert(!array.next(index, found));

    index = -1;
    assert(!array.next(index));

    index = -1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = -1;
    assert(array.prev(index));
    assert(index == 0);

    index = -1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);

    index = -1;
    assert(array.last(index));
    assert(index == 0);

}

unittest
{
    writeln("[JudyL UnitTest] - find with single element at end");

    auto array = JudyLArray!string();

    const auto END = size_t.max;

    string hello = "hello";
    array[END] = hello;

    string found;



    size_t index = 0;
    assert(array.first(index, found));
    assert(index == END);
    assert(found == hello);

    index = 0;
    assert(array.first(index));
    assert(index == END);
    assert(array.first() == END);

    index = 0;
    assert(array.next(index, found));
    assert(index == END);
    assert(found == hello);

    index = 0;
    assert(array.next(index));
    assert(index == END);

    index = 0;
    assert(!array.prev(index, found));
    assert(!array.prev(index));

    index = 0;
    assert(!array.last(index, found));

    index = 0;
    assert(!array.last(index));
    assert(array.last() == END);



    index = END - 1;
    assert(array.first(index, found));
    assert(index == END);
    assert(found == hello);

    index = END - 1;
    assert(array.first(index));
    assert(index == END);
            
    index = END - 1;
    assert(array.next(index, found));
    assert(index == END);
    assert(found == hello);

    index = END - 1;
    assert(array.next(index));
    assert(index == END);

    index = END - 1;
    assert(!array.prev(index, found));
    assert(!array.prev(index));

    index = END - 1;
    assert(!array.last(index, found));
    assert(!array.last(index));



    index = -1;
    assert(array.first(index, found));
    assert(index == END);
    assert(found == hello);

    index = -1;
    assert(array.first(index));
    assert(index == END);

    index = -1;
    assert(!array.next(index, found));

    index = -1;
    assert(!array.next(index));

    index = -1;
    assert(!array.prev(index, found));

    index = -1;
    assert(!array.prev(index));

    index = -1;
    assert(array.last(index, found));
    assert(index == END);
    assert(found == hello);

    index = -1;
    assert(array.last(index));
    assert(index == END);
}

unittest
{
    writeln("[JudyL UnitTest] - find with single element in middle");

    auto array = JudyLArray!string();

    string hello = "hello";
    array[10] = hello;

    string found;


    
    size_t index = 0;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 0;
    assert(array.first(index));
    assert(index == 10);
    assert(array.first() == 10);

    index = 0;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 0;
    assert(array.next(index));
    assert(index == 10);

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(!array.prev(index));

    index = 0;
    assert(!array.last(index, found));

    index = 0;
    assert(!array.last(index));
    assert(array.last() == 10);



    index = 10;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 10;
    assert(array.first(index));
    assert(index == 10);

    index = 10;
    assert(!array.next(index, found));
    assert(!array.next(index));

    index = 10;
    assert(!array.prev(index, found));
    assert(!array.prev(index));

    index = 10;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 10;
    assert(array.last(index));
    assert(index == 10);
   

 
    index = 11;
    assert(!array.first(index, found));
    assert(!array.first(index));

    index = 11;
    assert(!array.next(index, found));
    assert(!array.next(index));

    index = 11;
    assert(array.prev(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 11;
    assert(array.prev(index));
    assert(index == 10);

    index = 11;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 11;
    assert(array.last(index));
    assert(index == 10);



    index = -1;
    assert(array.prev(index, found));
    assert(index == 10);
    assert(found == hello);

    index = -1;
    assert(array.prev(index));
    assert(index == 10);

    index = -1;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == hello);

    index = -1;
    assert(array.last(index));
    assert(index == 10);
}

unittest
{
    writeln("[JudyL UnitTest] - find with multiple elements");

    auto array = JudyLArray!string();

    string hello = "hello";
    string world = "world";

    array[0] = hello;
    array[10] = world;

    string found;


    
    size_t index = 0;
    assert(array.first(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 0;
    assert(array.first(index));
    assert(index == 0);
    assert(array.first() == 0);

    index = 0;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == world);

    index = 0;
    assert(array.next(index));
    assert(index == 10);

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(!array.prev(index));

    index = 0;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 0;
    assert(array.last(index));
    assert(index == 0);
    assert(array.last() == 10);



    index = 1;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == world);

    index = 1;
    assert(array.first(index));
    assert(index == 10);

    index = 1;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == world);

    index = 1;
    assert(array.next(index));
    assert(index == 10);

    index = 1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 1;
    assert(array.prev(index));
    assert(index == 0);

    index = 1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 1;
    assert(array.last(index));
    assert(index == 0);



    index = 10;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == world);

    index = 10;
    assert(array.first(index));
    assert(index == 10);

    index = 10;
    assert(!array.next(index, found));
    assert(!array.next(index));

    index = 10;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 10;
    assert(array.prev(index));
    assert(index == 0);

    index = 10;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == world);

    index = 10;
    assert(array.last(index));
    assert(index == 10);
}

unittest
{
    writeln("[JudyL UnitTest] - find empty in empty array");

    auto array = JudyLArray!string();

    const auto END = size_t.max;

    size_t index = 0;
    assert(array.firstEmpty(index), "Find first empty");
    assert(index == 0);

    index = 0;
    assert(array.nextEmpty(index), "Find next empty");
    assert(index == 1);

    index = -1;
    assert(array.prevEmpty(index), "Find prev empty");
    assert(index == END - 1);

    index = -1;
    assert(array.lastEmpty(index), "Find last empty");
    assert(index == END);
}

unittest
{
    writeln("[JudyL UnitTest] - find empty with single element at start");

    auto array = JudyLArray!string();

    const auto END = size_t.max;

    string hello = "hello";
    array[0] = hello;

    size_t index = 0;
    assert(array.firstEmpty(index), "Find first empty");
    assert(index == 1);

    index = 0;
    assert(array.nextEmpty(index), "Find next empty");
    assert(index == 1);

    index = -1;
    assert(array.prevEmpty(index), "Find prev empty");
    assert(index == END - 1);

    index = -1;
    assert(array.lastEmpty(index), "Find last empty");
    assert(index == END);
}

unittest
{
    writeln("[JudyL UnitTest] - find empty with single element at end");

    auto array = JudyLArray!string();

    const auto END = size_t.max;

    string hello = "hello";
    array[END] = hello;

    size_t index = END;
    assert(!array.firstEmpty(index), "Find first empty");

    index = END;
    assert(!array.nextEmpty(index), "Find next empty");

    index = -1;
    assert(array.prevEmpty(index), "Find prev empty");
    assert(index == END - 1);

    index = -1;
    assert(array.lastEmpty(index), "Find last empty");
    assert(index == END - 1);
}

unittest
{
    writeln("[JudyL UnitTest] - find empty with single element in middle");

    auto array = JudyLArray!string();

    const auto END = size_t.max;

    string hello = "hello";
    array[10] = hello;

    size_t index = 0;
    assert(array.firstEmpty(index), "Find first empty");
    assert(index == 0);

    index = 0;
    assert(array.nextEmpty(index), "Find next empty");
    assert(index == 1);

    index = -1;
    assert(array.prevEmpty(index), "Find prev empty");
    assert(index == END - 1);

    index = -1;
    assert(array.lastEmpty(index), "Find last empty");
    assert(index == END);



    index = 9;
    assert(array.firstEmpty(index), "Find first empty");
    assert(index == 9);

    index = 9;
    assert(array.nextEmpty(index), "Find next empty");
    assert(index == 11);

    index = 11;
    assert(array.prevEmpty(index), "Find prev empty");
    assert(index == 9);

    index = 11;
    assert(array.lastEmpty(index), "Find last empty");
    assert(index == 11);



    index = 10;
    assert(array.firstEmpty(index), "Find first empty");
    assert(index == 11);

    index = 10;
    assert(array.nextEmpty(index), "Find next empty");
    assert(index == 11);

    index = 10;
    assert(array.prevEmpty(index), "Find prev empty");
    assert(index == 9);

    index = 10;
    assert(array.lastEmpty(index), "Find last empty");
    assert(index == 9);
}

