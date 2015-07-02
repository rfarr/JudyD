module judy.judyl;

import core.exception;
import core.memory;
import std.array;
import std.range;
import std.traits;

import judy.libjudy;

/*
    Provides D like wrapper around the libjudy C library.  Items in the array
    are indexed by size_t.

    Supports containing the following types:

        - Heap allocated references (classes)
        - Pointers to heap allocated structs, primitives (no indirections)
        - Stack scalar types (these are copied)

    Since libjudy is a C library, management of memory becomes an issue.
    By default for non scalar types JudyLArray will add stored
    items to the GC's roots.  This ensures that if the only pointer
    to your items is within the judy array that the items will not
    be collected.

    If you don't want to use the GC (you're using malloc or your own allocator),
    then it can be turned off by passing UseGC = false to the template
    parameters.

    NOTE: Passing in pointers to anything on the stack is very bad
    and will probably cause nasty things to happen.  JudyLArray
    assumes (other than for primitives which it just copies into itself)
    that your items are long living and won't be freed
    out from underneath it. You have been warned.
*/
struct JudyLArray(ElementType, bool UseGC = true) if (
    isPointer!ElementType && !hasIndirections!(PointerTarget!ElementType) ||
    is(ElementType : Object) ||
    isScalarType!ElementType
)
{
    public:
        @disable // no copying
        this(this);

        ~this()
        {
            static if (UseGC)
            {
                // Iterate over all entries and remove them from the GC
                foreach(ref entry; this)
                {
                    GC.removeRoot(cast(void*)entry.value);
                    GC.clrAttr(cast(void*)entry.value, GC.BlkAttr.NO_MOVE);
                }
            }
            // Free the actual array
            JudyLFreeArray(&array_, NO_ERROR);
        }

        // Is the array empty?
        @property bool empty() const nothrow @nogc
        {
            return count == 0;
        }

        // Returns number of elements in the Judy array
        @property size_t count() const nothrow @nogc
        {
            return JudyLCount(array_, 0, -1, NO_ERROR);
        }


        // Returns the index and element of first entry. Throws range error if empty.
        @property JudyLEntry front() const
        {
            size_t index = 0;
            auto value = cast(ElementType**)JudyLFirst(array_, &index, NO_ERROR);

            if (value !is null)
            {
                return JudyLEntry(index, *value);
            }
            throw new RangeError();
        }

        // Removes first element. Throws RangeError if empty.
        void popFront()
        {
            remove(first());
        }

        // Gets index and element of last entry. Throws RangeError if empty.
        @property JudyLEntry back() const
        {
            size_t index = -1;
            auto value = cast(ElementType**)JudyLLast(array_, &index, NO_ERROR);

            if (value !is null)
            {
                return JudyLEntry(index, *value);
            }
            throw new RangeError();
        }

        // Removes last element. Throws RangeError if empty.
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

        // Create a slice over the underlying Judy array
        auto opSlice() inout nothrow @nogc
        {
            return JudyLArrayRange(array_);
        }

        // Create a slice with given indices over the underlying Judy array
        auto opSlice(const size_t start, const size_t end) inout nothrow @nogc
        {
            return JudyLArrayRange(array_, start, end);
        }

        // Return highest index of element in array
        size_t opDollar() const
        {
            if (empty)
            {
                throw new RangeError();
            }
            return back.index;
        }
        
        
        // Get element at index
        ElementType opIndex(const size_t index) const
        {
            return get(index);
        }

        // Assign element to index
        void opIndexAssign(ElementType value, const size_t index)
        {
            insert(index, value);
        }

        // Add element at index
        void add(const size_t index, ElementType value)
        {
            insert(index, value);
        }

        // Get element at. Return true if found. Places element into value.
        bool at(const size_t index, out ElementType value) const nothrow @nogc
        {
            auto element = JudyLGet(array_, index, NO_ERROR);
            if (element is null)
            {
                return false;
            }
            value = cast(ElementType)(*element);
            return true;
        }

        // Check if has element at index
        bool has(const size_t index) const nothrow @nogc
        {
            return JudyLGet(array_, index, NO_ERROR) !is null;
        }


        // Find first element >= index. Returns true if found, sets index and element.
        bool first(ref size_t index, out ElementType found) const nothrow @nogc
        {
            auto value = cast(ElementType**)JudyLFirst(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = cast(ElementType)(*value);
            return true;
        }

        // Find first elem >= index. Returns true if found. Sets index.
        bool first(ref size_t index) const nothrow @nogc
        {
            return JudyLFirst(array_, &index, NO_ERROR) !is null;
        }

        // Get index of first element. Throws RangeError if empty.
        size_t first() const
        {
            return front.index;
        }

        // Find next element > index. Returns true if found. Sets index and element.
        bool next(ref size_t index, out ElementType found) const nothrow @nogc
        {
            auto value = cast(ElementType**)JudyLNext(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = cast(ElementType)(*value);
            return true;
        }

        // Find next element > index. Returns true if found. Sets index.
        bool next(ref size_t index) const nothrow @nogc
        {
            return JudyLNext(array_, &index, NO_ERROR) !is null;
        }

        // Find prev element < index. Returns true if found. Sets index and element.
        bool prev(ref size_t index, out ElementType found) const nothrow @nogc
        {
            auto value = cast(ElementType**)JudyLPrev(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = cast(ElementType)(*value);
            return true;
        }

        // Find prev element < index. Returns true if found. Sets index
        bool prev(ref size_t index) const nothrow @nogc
        {
            return JudyLPrev(array_, &index, NO_ERROR) !is null;
        }

        // Find last element <= index. Returns true if found. Sets index and element.
        bool last(ref size_t index, out ElementType found) const nothrow @nogc
        {
            auto value = cast(ElementType**)JudyLLast(array_, &index, NO_ERROR);
            if (value == null)
            {
                return false;
            }
            found = cast(ElementType)(*value);
            return true;
        }

        // Find last element <= index. Returns true if found. Sets index.
        bool last(ref size_t index) const
        {
            return JudyLLast(array_, &index, NO_ERROR) !is null;
        }

        // Get index of last element. Throws RangeError if empty.
        size_t last() const
        {
            return back.index;
        }


        // Find first empty slot >= index. Returns true if found. Sets index.
        bool firstEmpty(ref size_t index) const nothrow @nogc
        {
            return JudyLFirstEmpty(array_, &index, NO_ERROR) == 1;
        }

        // Find next empty slot > index. Returns true if found. Sets index.
        bool nextEmpty(ref size_t index) const nothrow @nogc
        {
            return JudyLNextEmpty(array_, &index, NO_ERROR) == 1;
        }

        // Find prev empty slot < index. Returns true if found. Sets index.
        bool prevEmpty(ref size_t index) const nothrow @nogc
        {
            return JudyLPrevEmpty(array_, &index, NO_ERROR) == 1;
        }

        // Find last empty slot <= index. Returns true if found. Sets index.
        bool lastEmpty(ref size_t index) const nothrow @nogc
        {
            return JudyLLastEmpty(array_, &index, NO_ERROR) == 1;
        }


        // Gets total amount of memory used by population and infrastructure
        @property size_t memUsed() const nothrow @nogc
        {
            return JudyLMemUsed(array_);
        }

        // Gets total amount of memory used by population (pointers only)
        @property size_t memActive() const nothrow @nogc
        {
            return JudyLMemActive(array_);
        }

    private:
        void* array_;

        // Insert element at index. Throws RangeError on insertion error.
        void insert(const size_t index, ElementType value)
        {
            auto element = JudyLIns(&array_, index, NO_ERROR);
            if (element is null)
            {
                throw new RangeError();
            }
            static if (UseGC && hasIndirections!ElementType)
            {
                GC.addRoot(cast(void*)value);
                GC.setAttr(cast(void*)value, GC.BlkAttr.NO_MOVE);
            }
            *element = cast(ElementType*)value;
        }

        /* Get element at index. Throws RangeError if not found. See `at`
           for exception safe version
        */
        ElementType get(const size_t index) const
        {
            auto element = JudyLGet(array_, index, NO_ERROR);
            if (element is null)
            {
                throw new RangeError();
            }
            return cast(ElementType)(*element);
        }

        // Remove element at index
        bool remove(const size_t index) nothrow
        {
            ElementType element;
            if (!at(index, element))
            {
                return false;
            }

            auto deleted = JudyLDel(&array_, index, NO_ERROR) == 1;

            if (deleted)
            {
                // Remove explicit root from GC since instance is back under runtime
                static if (UseGC && hasIndirections!ElementType)
                {
                    GC.removeRoot(cast(void*)element);
                    GC.clrAttr(cast(void*)element, GC.BlkAttr.NO_MOVE);
                }
            }

            return deleted;
        }

        // An entry containing the index and element. Used for iteration
        struct JudyLEntry
        {
            private:
                const size_t index_;
                ElementType* value_;

            public:
                this(const size_t index, ElementType* value)
                {
                    this.index_ = index;
                    this.value_ = value;
                }

                @property size_t index() const nothrow @nogc
                {
                    return index_;
                }

                @property ElementType value() nothrow @nogc
                {
                    return cast(ElementType)(value_);
                }
        }

        // Iteration struct, allows fast read only iteration of the underlying Judy array
        struct JudyLArrayRange
        {
            public:
                // Construct slice over entire array
                this(const void* array) nothrow @nogc
                {
                    this(array, 0UL, -1UL);
                }

                // Construct slice over given range
                this (const void* array, const size_t firstIndex, const size_t lastIndex) nothrow @nogc
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

                // Is slice empty?
                @property bool empty() const nothrow @nogc
                {
                    return frontPtr_ is null;
                }

                // Get first element/index of slice. Throws RangeError if empty.
                @property JudyLEntry front()
                {
                    if (frontPtr_ is null)
                    {
                        throw new RangeError();
                    }
                    return JudyLEntry(firstIndex_, frontPtr_);
                }

                // Discard first element and find next
                void popFront() nothrow @nogc
                {
                    auto element = cast(ElementType**)JudyLNext(array_, &firstIndex_, NO_ERROR);

                    // Empty check
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

                // Get last element/index of slice. Throws RangeError if empty.
                @property JudyLEntry back()
                {
                    if (backPtr_ is null)
                    {
                        throw new RangeError();
                    }
                    return JudyLEntry(lastIndex_, backPtr_);
                }

                // Discard last element of slice and find prev
                void popBack() nothrow @nogc
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

                // Get element at index. Throws RangeError if out of bounds or not found.
                ElementType opIndex(size_t index) const
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

                    return cast(ElementType)(*element);
                }

                // Save iteration state
                @property JudyLArrayRange save() nothrow @nogc
                {
                    return this;
                }

                // Get count of population in slice
                @property auto count() const nothrow @nogc
                {
                    return JudyLCount(array_, leftBound_, rightBound_, NO_ERROR);
                }

            private:
                ElementType* frontPtr_;
                ElementType* backPtr_;
                size_t leftBound_;
                size_t rightBound_;
                size_t firstIndex_;
                size_t lastIndex_;
                const void* array_;
        }
}



version(unittest)
{
    import std.conv;
    import std.exception;
    import std.stdio;

    class Data
    {
      public:
        this(int x)
        {
            this.x = x;
        }

        int x;

        override string toString()
        {
          return to!string(x);
        }
    }

    struct Point
    {
        int x;
        int y;

        ~this()
        {
            writeln(this);
        }
    }
}


unittest
{
    writeln("[UnitTest JudyL] - count");

    auto array = JudyLArray!Data();

    auto data = new Data(0);

    assert(array.count == 0, "Array starting count is 0");

    array[0] = data;
    assert(array.count == 1, "Array count updated");

    array[1] = data;
    assert(array.count == 2, "Array count updated");

    array.remove(0);
    assert(array.count == 1, "Array count updated");

    array.remove(1);
    assert(array.count == 0, "Array count updated");
}

unittest
{
    writeln("[UnitTest JudyL] - empty");

    auto array = JudyLArray!Data();

    auto data = new Data(0);

    assert(array.empty, "Array starts empty");

    array[0] = data;
    assert(!array.empty, "Array not empty");

    array.add(1, data);
    assert(!array.empty, "Array not empty");

    array.remove(0);
    array.remove(1);
    assert(array.empty, "Array now empty");
}

unittest
{
    writeln("[UnitTest JudyL] - has");

    auto array = JudyLArray!Data();

    auto data = new Data(0);

    assert(!array.has(0), "Array doesn't have element");
    assert(!array.has(1), "Array doesn't have element");

    array[0] = data;

    assert(array.has(0), "Array has element");
    assert(!array.has(1), "Array doesn't have element");

    array[1] = data;

    assert(array.has(0), "Array has element");
    assert(array.has(1), "Array has element");
}

unittest
{
    writeln("[UnitTest JudyL] - at");

    auto array = JudyLArray!Data();

    auto data0 = new Data(0);
    auto data1 = new Data(1);

    Data value;

    assert(!array.at(0, value), "Array doesn't have element");
    assert(!array.at(1, value), "Array doesn't have element");

    array[0] = data0;
    array[1] = data1;

    assert(array.at(0, value), "Array has element");
    assert(value == data0);

    assert(array.at(1, value), "Array has element");
    assert(value == data1);
}

unittest
{
    writeln("[UnitTest JudyL] - add");

    auto array = JudyLArray!Data();

    auto data0 = new Data(0);
    auto data1 = new Data(1);

    array.add(0, data0);
    array.add(1, data1);

    assert(array[0] == data0, "Array has element");
    assert(array[1] == data1, "Array has element");

    array.add(0,  data1);
    assert(array[0] == data1, "Element updated");
}

unittest
{
    writeln("[UnitTest JudyL] - opIndexAssign");

    auto array = JudyLArray!Data();

    auto data0 = new Data(0);
    auto data1 = new Data(1);

    array.add(0, data0);
    array.add(1, data1);

    array[0] = data0;
    assert(array[0] == data0, "Array has element");

    array[1] = data1;
    assert(array[1] == data1, "Array has element");

    array[0] = data1;
    assert(array[0] == data1, "Element updated");
}

unittest
{
    writeln("[UnitTest JudyL] - opIndex");

    auto array = JudyLArray!Data();

    auto data0 = new Data(0);
    auto data1 = new Data(1);

    assertThrown!RangeError(array[0], "Array doesn't have element");
    assertThrown!RangeError(array[1], "Array doesn't have element");

    array[0] = data0;
    assert(array[0] == data0, "Array has element");

    array[1] = data1;
    assert(array[1] == data1, "Array has element");
}

unittest
{
    writeln("[UnitTest JudyL] - remove");

    auto array = JudyLArray!Data();

    auto data = new Data(0);

    assert(!array.remove(0), "Array doesn't have element");

    array[0] = data;
    assert(array.remove(0), "Array had element");

    assert(!array.has(0), "Element removed");
}

unittest
{
    writeln("[UnitTest JudyL] - forward iteration");

    auto array = JudyLArray!Data();

    auto testrange = iota(100, 1000, 10);

    Data[int] datas = assocArray(
        zip(
            testrange,
            map!(a => new Data(a))(testrange).array
        )
    );

    foreach(data; array)
    {
        assert(false, "Empty array");
    }

    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = datas[i];
    }

    auto j = 0;
    foreach(ref data; array)
    {
        assert(data.index == testrange[j]);
        assert(data.value == array[testrange[j++]]);
    }
    assert(array.count == testrange.length, "Forward iteration leaves data intact");
}

unittest
{
    writeln("[UnitTest JudyL] - front and back");

    auto array = JudyLArray!Data();

    auto testrange = iota(100, 1000, 10);

    Data[int] datas = assocArray(
        zip(
            testrange,
            map!(a => new Data(a))(testrange).array
        )
    );

    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = datas[i];
    }

    // Verify front and back
    assert(array.front.index == 100, "Correct front");
    assert(array.front.value == datas[100], "Correct front");
    assert(array.back.index == 990, "Correct back");
    assert(array.back.value == datas[990], "Correct back");


    // Remove front
    array.remove(100);
    assert(array.front.index == 110, "Front updated");
    assert(array.front.value == datas[110], "Front updated");
    assert(array.back.index == 990, "Back unchanged");
    assert(array.back.value == datas[990], "Back unchanged");

    // Remove back
    array.remove(990);
    assert(array.front.index == 110, "Front unchanged");
    assert(array.front.value == datas[110], "Front unchanged");
    assert(array.back.index == 980, "Back updated");
    assert(array.back.value == datas[980], "Back updated");

    // Remove middle
    array.remove(550);
    assert(array.front.index == 110, "Front unchanged");
    assert(array.front.value == datas[110], "Front unchanged");
    assert(array.back.index == 980, "Back updated");
    assert(array.back.value == datas[980], "Back updated");
}

unittest
{
    writeln("[UnitTest JudyL] - popFront and popBack");

    auto array = JudyLArray!Data();

    auto testrange = iota(0, 10);

    Data[int] datas = assocArray(
        zip(
            testrange,
            map!(a => new Data(a))(testrange).array
        )
    );

    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = datas[i];
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
    writeln("[UnitTest JudyL] - free memory");

    JudyLArray!Data* ptr;

    {
        auto array = JudyLArray!Data();

        assert(array.memUsed == 0, "No memory used on empty array");
        assert(array.memActive == 0, "No memory active on empty array");

        auto testrange = iota(0, 100);

        Data[int] datas = assocArray(
            zip(
                testrange,
                map!(a => new Data(a))(testrange).array
            )
        );

        // Insert some elements
        foreach(i; testrange)
        {
            array[i] = datas[i];
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
    writeln("[UnitTest JudyL] - opSlice");

    auto array = JudyLArray!Data();

    auto testrange = iota(0, 100);

    Data[int] datas = assocArray(
        zip(
            testrange,
            map!(a => new Data(a))(testrange).array
        )
    );

    // Test empty
    foreach(data; array[])
    {
        assert(false, "empty array");
    }

    // Test one element
    array[1000] = datas[0];
    int j = 0;
    foreach(ref data; array[])
    {
        assert(j++ == 0, "Called once");
        assert(data.index == 1000, "Index preserved");
        assert(data.value == datas[0]);
    }
    array.remove(1000);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = datas[i];
    }

    assert(array.count == array[].count, "Array and slice count the same");

    j = 0;
    foreach(ref data; array[])
    {
        assert(data.index == testrange[j]);
        assert(data.value == datas[j++], "Forward range iteration");
    }

    // backwards iteration
    j = testrange[$-1];
    foreach(ref data; retro(array[]))
    {
        assert(data.index == testrange[j]);
        assert(data.value == datas[j--], "Retrograde range iteration");
    }

    auto slice = array[];
    foreach(i; testrange)
    {
        assert(slice[i] == array[i], "Slice random access");
    }

    assertThrown!RangeError(slice[200], "Out of bounds");

    auto data1 = new Data(-7);
    auto data2 = new Data(-10);

    array[50] = data1;
    array[10000] = data2;

    assert(slice[50] == data1, "Array mutation reflected in slice");
    assert(slice[10000] == data2, "Array insertion reflected in slice");
}

unittest
{
    writeln("[UnitTest JudyL] - opSlice[x..y]");

    auto array = JudyLArray!Data();

    auto testrange = iota(0, 100);

    Data[int] datas = assocArray(
        zip(
            testrange,
            map!(a => new Data(a))(testrange).array
        )
    );

    // Test empty
    foreach(data; array[1..2])
    {
        assert(false, "empty array");
    }

    // Test one element
    array[2] = datas[0];
    int j = 0;
    foreach(ref data; array[0..5])
    {
        assert(j == 0, "Called once");
        assert(data.index == 2);
        assert(data.value == datas[0]);
    }
    array.remove(2);
    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = datas[i];
    }

    j = 20;
    foreach(ref data; array[20..30])
    {
        assert(data.index == j);
        assert(data.value == datas[j++], "Indexed slice");
    }

    j = 20;
    foreach(ref data; array[20..500])
    {
        assert(data.index == j);
        assert(data.value == datas[j++], "Indexed slice beyond population");
    }

    j = 90;
    foreach(ref data; array[90..$])
    {
        assert(data.index == j);
        assert(data.value == datas[j++], "OpDollar slice");
    }

    j = 20;
    foreach(ref data; retro(array[10..20]))
    {
        assert(data.index == j);
        assert(data.value == datas[j--], "Retrograde slice");
    }

    auto slice = array[50..$];
    foreach(i; 50..100)
    {
        assert(slice[i] == array[i], "Random access");
    }

    assertThrown!RangeError(array[10..20][9], "Out of bounds");
    assertThrown!RangeError(array[10..20][21], "Out of bounds");

    auto data1 = new Data(-3);
    auto data2 = new Data(-4);

    array[67] = data1;

    assert(slice[67] == data1, "Array mutation reflected in slice");
}

unittest
{
    writeln("[UnitTest JudyL] - opDollar");

    auto array = JudyLArray!Data();

    auto testrange = iota(0, 100, 5);

    Data[int] datas = assocArray(
        zip(
            testrange,
            map!(a => new Data(a))(testrange).array
        )
    );

    // Test empty
    assertThrown!RangeError(array[$]);

    // Test one element
    array[0] = datas[0];
    array[$] = datas[5];
    assert(array[0] == datas[5]);
    array.remove(0);

    
    // Insert some elements
    foreach(i; testrange)
    {
        array[i] = datas[i];
    }

    array[$] = datas[0];

    assert(array[95] == datas[0], "opDollar is last index");

    auto data1 = new Data(77);
    array[size_t.max] = data1;

    auto slice = array[95..$];
    assert(slice.count == 2);
    assert(slice[95] == datas[0]);
    assert(slice[size_t.max] == data1);
}


unittest
{
    writeln("[UnitTest JudyL] - find in empty array");

    auto array = JudyLArray!Data();

    Data found;
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
    writeln("[UnitTest JudyL] - find with single element at start");

    auto array = JudyLArray!Data();

    auto data = new Data(1);
    array[0] = data;

    Data found;



    size_t index = 0;
    assert(array.first(index, found));
    assert(index == 0);
    assert(found == data);

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
    assert(found == data);

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
    assert(found == data);

    index = 1;
    assert(array.prev(index));
    assert(index == 0);

    index = 1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == data);

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
    assert(found == data);

    index = -1;
    assert(array.prev(index));
    assert(index == 0);

    index = -1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == data);

    index = -1;
    assert(array.last(index));
    assert(index == 0);

}

unittest
{
    writeln("[UnitTest JudyL] - find with single element at end");

    auto array = JudyLArray!Data();

    const auto END = size_t.max;

    auto data = new Data(0);
    array[END] = data;

    Data found;



    size_t index = 0;
    assert(array.first(index, found));
    assert(index == END);
    assert(found == data);

    index = 0;
    assert(array.first(index));
    assert(index == END);
    assert(array.first() == END);

    index = 0;
    assert(array.next(index, found));
    assert(index == END);
    assert(found == data);

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
    assert(found == data);

    index = END - 1;
    assert(array.first(index));
    assert(index == END);
            
    index = END - 1;
    assert(array.next(index, found));
    assert(index == END);
    assert(found == data);

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
    assert(found == data);

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
    assert(found == data);

    index = -1;
    assert(array.last(index));
    assert(index == END);
}

unittest
{
    writeln("[UnitTest JudyL] - find with single element in middle");

    auto array = JudyLArray!Data();

    auto data = new Data(0);
    array[10] = data;

    Data found;


    
    size_t index = 0;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == data);

    index = 0;
    assert(array.first(index));
    assert(index == 10);
    assert(array.first() == 10);

    index = 0;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == data);

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
    assert(found == data);

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
    assert(found == data);

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
    assert(found == data);

    index = 11;
    assert(array.prev(index));
    assert(index == 10);

    index = 11;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == data);

    index = 11;
    assert(array.last(index));
    assert(index == 10);



    index = -1;
    assert(array.prev(index, found));
    assert(index == 10);
    assert(found == data);

    index = -1;
    assert(array.prev(index));
    assert(index == 10);

    index = -1;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == data);

    index = -1;
    assert(array.last(index));
    assert(index == 10);
}

unittest
{
    writeln("[UnitTest JudyL] - find with multiple elements");

    auto array = JudyLArray!Data();

    auto data1 = new Data(0);
    auto data2 = new Data(1);

    array[0] = data1;
    array[10] = data2;

    Data found;


    
    size_t index = 0;
    assert(array.first(index, found));
    assert(index == 0);
    assert(found == data1);

    index = 0;
    assert(array.first(index));
    assert(index == 0);
    assert(array.first() == 0);

    index = 0;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == data2);

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
    assert(found == data1);

    index = 0;
    assert(array.last(index));
    assert(index == 0);
    assert(array.last() == 10);



    index = 1;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == data2);

    index = 1;
    assert(array.first(index));
    assert(index == 10);

    index = 1;
    assert(array.next(index, found));
    assert(index == 10);
    assert(found == data2);

    index = 1;
    assert(array.next(index));
    assert(index == 10);

    index = 1;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == data1);

    index = 1;
    assert(array.prev(index));
    assert(index == 0);

    index = 1;
    assert(array.last(index, found));
    assert(index == 0);
    assert(found == data1);

    index = 1;
    assert(array.last(index));
    assert(index == 0);



    index = 10;
    assert(array.first(index, found));
    assert(index == 10);
    assert(found == data2);

    index = 10;
    assert(array.first(index));
    assert(index == 10);

    index = 10;
    assert(!array.next(index, found));
    assert(!array.next(index));

    index = 10;
    assert(array.prev(index, found));
    assert(index == 0);
    assert(found == data1);

    index = 10;
    assert(array.prev(index));
    assert(index == 0);

    index = 10;
    assert(array.last(index, found));
    assert(index == 10);
    assert(found == data2);

    index = 10;
    assert(array.last(index));
    assert(index == 10);
}

unittest
{
    writeln("[UnitTest JudyL] - find empty in empty array");

    auto array = JudyLArray!Data();

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
    writeln("[UnitTest JudyL] - find empty with single element at start");

    auto array = JudyLArray!Data();

    const auto END = size_t.max;

    auto data = new Data(0);
    array[0] = data;

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
    writeln("[UnitTest JudyL] - find empty with single element at end");

    auto array = JudyLArray!Data();

    const auto END = size_t.max;

    auto data = new Data(0);
    array[END] = data;

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
    writeln("[UnitTest JudyL] - find empty with single element in middle");

    auto array = JudyLArray!Data();

    const auto END = size_t.max;

    auto data = new Data(0);
    array[10] = data;

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

unittest
{
    writeln("[UnitTest JudyL] - struct pointer");

    auto array = JudyLArray!(Point*)();

    {
        auto point1 = new Point(1, 1);
        auto point2 = new Point(2, 2);

        array[0] = point1;
        array[1] = point2;
    }

    assert(array[0].x == 1);
    assert(array[0].y == 1);

    assert(array[1].x == 2);
    assert(array[1].y == 2);

    array.remove(0);
    array.remove(1);
}

unittest
{
    writeln("[UnitTest JudyL] - primitive pointer");

    auto array = JudyLArray!(int*)();

    {
        auto data1 = new int(7);
        auto data2 = new int(10);

        array[0] = data1;
        array[1] = data2;
    }

    assert(*array[0] == 7);
    assert(*array[1] == 10);

    array.remove(0);
    array.remove(1);
}

unittest
{
    writeln("[UnitTest JudyL] - primitive");

    auto array = JudyLArray!(int)();

    {
        array[0] = 7;
        array[1] = 10;
        array[0] = 3;
        array[2] = array[0] * array[1];
    }

    assert(array[0] == 3);
    assert(array[1] == 10);
    assert(array[2] == 30);

    array.remove(0);
    array.remove(1);
}
