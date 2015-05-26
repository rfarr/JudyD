module judy.judyl;

import core.exception;
import core.memory;
import std.array;
import std.range;

import judy.external;

struct JudyLArray(ElementType : Object)
{
    private:
        void* array_;

        void insert(const size_t index, ElementType value)
        {
            auto element = cast(ElementType**)JudyLIns(&array_, index, NO_ERROR);
            if (element is null)
            {
                throw new RangeError();
            }
            GC.addRoot(cast(void*)value);
            *element = cast(ElementType*)value;
        }

        ElementType get(const size_t index) const
        {
            auto element = cast(ElementType**)JudyLGet(array_, index, NO_ERROR);
            if (element is null)
            {
                throw new RangeError();
            }
            return cast(ElementType)(*element);
        }

        bool remove(const size_t index)
        {
            ElementType element;
            if (!at(index, element))
            {
                return false;
            }

            auto deleted = JudyLDel(&array_, index, NO_ERROR) == 1;

            if (deleted)
            {
                GC.removeRoot(cast(void*)element);
            }

            return deleted;
        }

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

                @property size_t index()
                {
                    return index_;
                }

                @property ElementType value()
                {
                    return cast(ElementType)(value_);
                }
        }


    public:

        @disable
        this(this);

        ~this()
        {
            foreach(ref entry; this)
            {
                GC.removeRoot(cast(void*)entry.value);
            }
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


        auto opSlice() inout
        {
            return JudyLArrayRange(array_);
        }

        auto opSlice(const size_t start, const size_t end) inout
        {
            return JudyLArrayRange(array_, start, end);
        }

        size_t opDollar() const
        {
            if (empty)
            {
                throw new RangeError();
            }
            return back.index;
        }
        
        
        
        ElementType opIndex(const size_t index) const
        {
            return get(index);
        }

        void opIndexAssign(ElementType value, const size_t index)
        {
            insert(index, value);
        }

        void add(const size_t index, ElementType value)
        {
            insert(index, value);
        }


        bool at(const size_t index, out ElementType value) const
        {
            auto element = cast(ElementType**)JudyLGet(array_, index, NO_ERROR);
            if (element is null)
            {
                return false;
            }
            value = cast(ElementType)(*element);
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
            found = cast(ElementType)(*value);
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
            found = cast(ElementType)(*value);
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
            found = cast(ElementType)(*value);
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
            found = cast(ElementType)(*value);
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
        struct JudyLArrayRange
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

                @property JudyLEntry front()
                {
                    if (frontPtr_ is null)
                    {
                        throw new RangeError();
                    }
                    return JudyLEntry(firstIndex_, frontPtr_);
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

                @property JudyLEntry back()
                {
                    if (backPtr_ is null)
                    {
                        throw new RangeError();
                    }
                    return JudyLEntry(lastIndex_, backPtr_);
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

                @property JudyLArrayRange save()
                {
                    return this;
                }

                @property auto count() const
                {
                    return JudyLCount(array_, leftBound_, rightBound_, NO_ERROR);
                }
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
}


unittest
{
    writeln("[JudyL UnitTest] - count");

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
    writeln("[JudyL UnitTest] - empty");

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
    writeln("[JudyL UnitTest] - has");

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
    writeln("[JudyL UnitTest] - at");

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
    writeln("[JudyL UnitTest] - add");

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
    writeln("[JudyL UnitTest] - opIndexAssign");

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
    writeln("[JudyL UnitTest] - opIndex");

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
    writeln("[JudyL UnitTest] - remove");

    auto array = JudyLArray!Data();

    auto data = new Data(0);

    assert(!array.remove(0), "Array doesn't have element");

    array[0] = data;
    assert(array.remove(0), "Array had element");

    assert(!array.has(0), "Element removed");
}

unittest
{
    writeln("[JudyL UnitTest] - forward iteration");

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
    writeln("[JudyL UnitTest] - front and back");

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
    writeln("[JudyL UnitTest] - popFront and popBack");

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
    writeln("[JudyL UnitTest] - free memory");

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
    writeln("[JudyL UnitTest] - opSlice");

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
    writeln("[JudyL UnitTest] - opSlice[x..y]");

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
    writeln("[JudyL UnitTest] - opDollar");

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
    writeln("[JudyL UnitTest] - find in empty array");

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
    writeln("[JudyL UnitTest] - find with single element at start");

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
    writeln("[JudyL UnitTest] - find with single element at end");

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
    writeln("[JudyL UnitTest] - find with single element in middle");

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
    writeln("[JudyL UnitTest] - find with multiple elements");

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
    writeln("[JudyL UnitTest] - find empty in empty array");

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
    writeln("[JudyL UnitTest] - find empty with single element at start");

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
    writeln("[JudyL UnitTest] - find empty with single element at end");

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
    writeln("[JudyL UnitTest] - find empty with single element in middle");

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
