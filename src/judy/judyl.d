module judy.judyl;

import std.array;
import std.range;
import std.string;

import judy.external;

class ElementNotFoundException : Exception
{
    this(const size_t index)
    {
        super(format("Element at index (%s) not found", index));
    }
}

struct JudyLArray(ElementType)
{
    private:
        void* array_;

        struct JudyLEntry(ElementType)
        {
            public:
                size_t index;
                ElementType value;

                this(size_t index, ref ElementType value)
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
            return length == 0;
        }

        /* Returns number of elements in the Judy array */
        @property size_t length() const
        {
            return JudyLCount(array_, 0, -1, NO_ERROR);
        }



        @property Entry front() const
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = 0;
            auto value = **cast(ElementType**)JudyLFirst(array_, &index, NO_ERROR);

            return Entry(index, value);
        }

        void popFront()
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = 0;
            JudyLFirst(array_, &index, NO_ERROR);
            JudyLDel(&array_, index, NO_ERROR);
        }



        @property Entry back() const
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = -1;
            auto value = **cast(ElementType**)JudyLLast(array_, &index, NO_ERROR);

            return Entry(index, value);
        }

        void popBack()
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = -1;
            JudyLLast(array_, &index, NO_ERROR);
            JudyLDel(&array_, index, NO_ERROR);
        }



        @property JudyLArrayRange!ElementType save() const
        {
            return JudyLArrayRange!ElementType(array_);
        }



        auto opSlice() const
        {
            return JudyLArrayRange!ElementType(array_);
        }

        auto opSlice(const size_t start, const size_t end) const
        {
            return JudyLArrayRange!ElementType(array_, start, end);
        }

        /* Get the last index of the array */
        size_t opDollar() const
        {
            size_t index = -1;
            if (JudyLLast(array_, &index, NO_ERROR) is null)
            {
                throw new RangeError();
            }
            return index;
        }



        ref ElementType opIndex(const size_t index) const
        {
            auto element = cast(ElementType**)JudyLGet(array_, index, NO_ERROR);

            if (element is null)
            {
                throw new ElementNotFoundException(index);
            }

            return **element;
        }



        void opIndexAssign(ref ElementType value, const size_t index)
        {
            auto element = cast(ElementType**)JudyLIns(&array_, index, NO_ERROR);
            *element = &value;
        }

        void add(ref ElementType value, const size_t index)
        {
            this[index] = value;
        }

        bool remove(const size_t index)
        in
        {
            assert(!empty);
        }
        body
        {
            return JudyLDel(&array_, index, NO_ERROR) == 1;
        }

        bool has(const size_t index)
        {
            return JudyLGet(array_, index, NO_ERROR) !is null;
        }

        /* Search functions for finding elements */
        bool first(ref size_t index, ref ElementType found) const
        {
            auto value = cast(ElementType**)JudyLFirst(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool next(ref size_t index, ref ElementType found) const
        {
            auto value = cast(ElementType**)JudyLNext(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool prev(ref size_t index, ref ElementType found) const
        {
            auto value = cast(ElementType**)JudyLPrev(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
        }

        bool last(ref size_t index, ref ElementType found) const
        {
            auto value = cast(ElementType**)JudyLLast(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = **value;
            return true;
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
                ElementType** frontPtr_;
                ElementType** backPtr_;
                size_t firstIndex_;
                size_t lastIndex_;
                const void* array_;

            public:
                this(const ref void* array)
                {
                    array_ = array;
                    firstIndex_ = 0;
                    lastIndex_ = -1;

                    frontPtr_ = cast(ElementType**)JudyLFirst(array_, &firstIndex_, NO_ERROR);
                    backPtr_ = cast(ElementType**)JudyLLast(array_, &lastIndex_, NO_ERROR);

                    // Empty
                    if (frontPtr_ is null || backPtr_ is null)
                    {
                        firstIndex_ = lastIndex_ = 0;
                    }
                }

                this (const ref void* array, const ref size_t firstIndex, const ref size_t lastIndex)
                {
                    array_ = array;
                    firstIndex_ = firstIndex;
                    lastIndex_ = lastIndex;

                    frontPtr_ = cast(ElementType**)JudyLGet(array, firstIndex_, NO_ERROR);
                    backPtr_ = cast(ElementType**)JudyLGet(array, lastIndex_, NO_ERROR);

                    // Empty
                    if (frontPtr_ is null || backPtr_ is null)
                    {
                        firstIndex_ = lastIndex_ = 0;
                    }
                }

                @property bool empty() const
                {
                    return firstIndex_ == lastIndex_;
                }

                @property Entry front()
                in
                {
                    assert(!empty);
                }
                body
                {
                    return Entry(firstIndex_, **frontPtr_);
                }

                void popFront()
                {
                    frontPtr_ = cast(ElementType**)JudyLNext(array_, &firstIndex_, NO_ERROR);
                }

                @property Entry back()
                in
                {
                    assert(!empty);
                }
                body
                {
                    return Entry(lastIndex_, **backPtr_);
                }

                void popBack()
                {
                    backPtr_ = cast(ElementType**)JudyLPrev(array_, &lastIndex_, NO_ERROR);
                }

                ref ElementType opIndex(const size_t index) const
                {
                    if (index < firstIndex_ || index > lastIndex_)
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

                size_t opDollar()
                {
                    return back.index;
                }

                @property JudyLArrayRange!ElementType save()
                {
                    return this;
                }

                @property auto length() const
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
    writeln("[JudyL UnitTest] - basic insert, remove, iteration");

    auto array = JudyLArray!string();

    assert(array.length == 0, "Array starting length is 0");
    assert(!array.has(100), "Element not in array");

    auto testrange = iota(100, 1000, 10);

    // Alocate storage for the string values on the stack
    string[int] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Insert some elements
    auto len = 0;
    foreach(i; testrange)
    {
        array[i] = strings[i];
        assert(array.length == ++len, "Length updates on insert");
    }

    // Verify front and back
    assert(array.front.index == 100, "Correct front");
    assert(array.front.value == "100", "Correct front");
    assert(array.back.index == 990, "Correct back");
    assert(array.back.value == "990", "Correct back");

    // Verify elements by opIndex
    foreach(i; testrange)
    {
        assert(array[i] == strings[i], "Iteration via opIndex");
        assert(array.has(i), "Index in array");
    }

    // Verify elements by inputRange
    auto j = 0;
    foreach(ref str; array)
    {
        assert(str.index == testrange[j], "Iteration via inputRange");
        assert(str.value == strings[testrange[j++]], "Iteration via inputRange");
    }

    // Remove front
    array.remove(100);
    assertThrown!ElementNotFoundException(array[100], "Element not found");
    assert(!array.has(100), "Element removed");
    assert(array.front.index == 110, "Front updated");
    assert(array.front.value == "110", "Front updated");
    assert(array.back.index == 990, "Back unchanged");
    assert(array.back.value == "990", "Back unchanged");
    assert(array.length == --len, "Length updated");

    // Remove back
    array.remove(990);
    assertThrown!ElementNotFoundException(array[990], "Element not found");
    assert(!array.has(990), "Element removed");
    assert(array.front.index == 110, "Front unchanged");
    assert(array.front.value == "110", "Front unchanged");
    assert(array.back.index == 980, "Back updated");
    assert(array.back.value == "980", "Back updated");
    assert(array.length == --len, "Length updated");

    // Remove middle
    array.remove(550);
    assertThrown!ElementNotFoundException(array[550], "Element not found");
    assert(!array.has(550), "Element removed");
    assert(array.front.index == 110, "Front unchanged");
    assert(array.front.value == "110", "Front unchanged");
    assert(array.back.index == 980, "Back updated");
    assert(array.back.value == "980", "Back updated");
    assert(array.length == --len, "Length updated");

    auto newrange = testrange.filter!(a => a != 100 && a != 550 && a != 990).array;

    // Verify elements by opIndex
    foreach(i; newrange)
    {
        assert(array[i] == strings[i], "Iteration via opIndex");
    }

    // Verify elements by inputRange
    j = 0;
    foreach(ref str; array)
    {
        assert(str.index == newrange[j], "Iteration via inputRange");
        assert(str.value == strings[newrange[j++]], "Iteration via inputRange");
    }
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

        assert(array.length == 100, "Length updated");
        assert(array.memUsed > 0, "Memory used");
        assert(array.memActive > 0, "Memory active");

        ptr = &array;
    }

    assert(ptr.length == 0, "Length cleared");
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
    array[0] = strings[0];
    size_t j = 0;
    foreach(ref str; array[])
    {
        assert(j == 0, "Called once");
        assert(str.value == strings[j++]);
    }
    array.remove(0);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    j = 0;
    foreach(ref str; array[])
    {
        assert(str.value == strings[j++], "Forward range iteration");
    }

    // backwards iteration
    j = array.length;
    foreach(ref str; retro(array[]))
    {
        assert(str.value == strings[--j], "Retrograde range iteration");
    }

    auto slice = array[];
    assert(slice.length == array.length, "Slice length the same");

    foreach(i; testrange)
    {
        assert(slice[i] == array[i], "Slice random access");
    }

    assertThrown!RangeError(slice[200], "Out of bounds");
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
    array[0] = strings[0];
    size_t j = 0;
    foreach(ref str; array[0..5])
    {
        assert(j == 0, "Called once");
        assert(str.value == strings[j++]);
    }
    array.remove(0);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    j = 20;
    foreach(ref str; array[20..30])
    {
        assert(str.value == strings[j++], "Indexed slice");
    }

    j = 90;
    foreach(ref str; array[90..$])
    {
        assert(str.value == strings[j++], "OpDollar slice");
    }

    j = 20;
    foreach(ref str; retro(array[10..20]))
    {
        assert(str.value == strings[j--], "Retrograde slice");
    }

    assertThrown!RangeError(array[10..20][9], "Out of bounds");
    assertThrown!RangeError(array[10..20][21], "Out of bounds");
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
    assertThrown!RangeError(array[$] = strings[0], "Out of bounds");

    // Test one element
    array[0] = strings[0];
    assert(array[$] == strings[0]);
    array.remove(0);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = strings[i];
    }

    array[$-1] = strings[0];

    assert(array[94] == strings[0], "opDollar is last index");

    array[100] = strings[5];
    assert(array[$] == strings[5], "opDollar updated on insert");

    array.remove(100);
    array.remove(95);
    array.remove(94);

    array[$] = strings[0];
    assert(array[90] == strings[0], "opDollar updated on remove");
}

unittest
{
    writeln("[JudyL UnitTest] - find in empty array");

    auto array = JudyLArray!string();

    string found;
    size_t index = 0;
    assert(!array.first(index, found), "Empty array");

    index = 0;
    assert(!array.next(index, found), "Empty array");

    index = -1;
    assert(!array.prev(index, found), "Empty array");

    index = -1;
    assert(!array.last(index, found), "Empty array");
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
    assert(!array.next(index, found));

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);



    index = 1;
    assert(!array.first(index, found));

    index = 1;
    assert(!array.next(index, found));

    index = 1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);



    index = -1;
    assert(!array.first(index, found));

    index = -1;
    assert(!array.next(index, found));

    index = -1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = -1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);

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
    assert(array.next(index, found));
    assert(index == END);
    assert(found == hello);

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(!array.last(index, found));



    index = END - 1;
    assert(array.first(index, found));
    assert(index == END);
    assert(found == hello);

    index = END - 1;
    assert(array.next(index, found));
    assert(index == END);
    assert(found == hello);

    index = END - 1;
    assert(!array.prev(index, found));

    index = END - 1;
    assert(!array.last(index, found));



    index = -1;
    assert(array.first(index, found));
    assert(index == END);
    assert(found == hello);

    index = -1;
    assert(!array.next(index, found));

    index = -1;
    assert(!array.prev(index, found));

    index = -1;
    assert(array.last(index, found));
    assert(index == END);
    assert(found == hello);
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
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(!array.last(index, found));



    index = 10;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 10;
    assert(!array.next(index, found));

    index = 10;
    assert(!array.prev(index, found));

    index = 10;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == hello);
   

 
    index = 11;
    assert(!array.first(index, found));

    index = 11;
    assert(!array.next(index, found));

    index = 11;
    assert(array.prev(index, found));
    assert(index == 10);
    assert(found == hello);

    index = 11;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == hello);



    index = -1;
    assert(array.prev(index, found));
    assert(index == 10);
    assert(found == hello);

    index = -1;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == hello);
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
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == world);

    index = 0;
    assert(!array.prev(index, found));

    index = 0;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);



    index = 1;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == world);

    index = 1;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == world);

    index = 1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == hello);



    index = 10;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == world);

    index = 10;
    assert(!array.next(index, found));

    index = 10;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == hello);

    index = 10;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == world);
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

