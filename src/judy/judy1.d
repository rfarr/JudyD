module judy.Judy1;

import core.exception;
import std.array;
import std.range;

import judy.external;

struct Judy1Array
{
    private:
        void* array_;

    public:
        ~this()
        {
            Judy1FreeArray(&array_, NO_ERROR);
        }

        @property bool empty() const
        {
            return count == 0;
        }

        /* Returns number of set bit in the Judy array */
        @property size_t count() const
        {
            return Judy1Count(array_, 0, -1, NO_ERROR);
        }



        @property size_t front() const
        {
            size_t index = 0;
            if (first(index))
            {
                return index;
            }
            throw new RangeError();
        }

        void popFront()
        {
            size_t index = 0;
            if (first(index))
            {
                unset(index);
            }
            else
            {
                throw new RangeError();
            }
        }



        @property size_t back() const
        {
            size_t index = -1;
            if (last(index))
            {
                return index;
            }
            throw new RangeError();
        }

        void popBack()
        {
            size_t index = -1;
            if (last(index))
            {
                unset(index);
            }
            else
            {
                throw new RangeError();
            }
        }



        auto opSlice() const
        {
            return Judy1ArrayRange(array_);
        }

        auto opSlice(const size_t start, const size_t end) const
        {
            return Judy1ArrayRange(array_, start, end);
        }

        size_t opDollar() const
        {
            if (empty)
            {
                throw new RangeError();
            }
            return back;
        }



        bool opIndex(const size_t index) const
        {
            return Judy1Test(array_, index, NO_ERROR) == 1;
        }



        void opIndexAssign(bool value, const size_t index)
        {
            if (value)
            {
                set(index);
            }
            else
            {
                unset(index);
            }
        }

        bool set(const size_t index)
        {
            return Judy1Set(&array_, index, NO_ERROR) == 1;
        }

        bool unset(const size_t index)
        {
            return Judy1Unset(&array_, index, NO_ERROR) == 1;
        }


        
        /* Search functions */
        bool first(ref size_t index) const
        {
            return Judy1First(array_, &index, NO_ERROR) == 1;
        }

        size_t first() const
        {
            return front;
        }

        bool next(ref size_t index) const
        {
            return Judy1Next(array_, &index, NO_ERROR) == 1;
        }

        bool prev(ref size_t index) const
        {
            return Judy1Prev(array_, &index, NO_ERROR) == 1;
        }

        bool last(ref size_t index) const
        {
            return Judy1Last(array_, &index, NO_ERROR) == 1;
        }

        size_t last() const
        {
            return back;
        }


        /* Search functions for finding empty */
        bool firstEmpty(ref size_t index) const
        {
            return Judy1FirstEmpty(array_, &index, NO_ERROR) == 1;
        }

        bool nextEmpty(ref size_t index) const
        {
            return Judy1NextEmpty(array_, &index, NO_ERROR) == 1;
        }

        bool prevEmpty(ref size_t index) const
        {
            return Judy1PrevEmpty(array_, &index, NO_ERROR) == 1;
        }

        bool lastEmpty(ref size_t index) const
        {
            return Judy1LastEmpty(array_, &index, NO_ERROR) == 1;
        }



        @property size_t memUsed() const
        {
            return Judy1MemUsed(array_);
        }

        @property size_t memActive() const
        {
            return Judy1MemActive(array_);
        }

        /* Iteration struct, allows fast read only iteration of the underlying Judy array */
        struct Judy1ArrayRange
        {
            private:
                size_t leftBound_;
                size_t rightBound_;
                size_t firstIndex_;
                size_t lastIndex_;
                const void* array_;

            public:
                this(const ref void* array)
                {
                    this(array, 0UL, -1UL);
                }

                this(const ref void* array, const size_t firstIndex, const size_t lastIndex)
                {
                    array_ = array;
                    leftBound_ = firstIndex_ = firstIndex;
                    rightBound_ = lastIndex_ = lastIndex;

                    if (
                        Judy1First(array_, &firstIndex_, NO_ERROR) != 1 ||
                        Judy1Last(array_, &lastIndex_, NO_ERROR) != 1
                    )
                    {
                        firstIndex_ = 1;
                        lastIndex_ = 0;
                    }

                }

                @property bool empty() const
                {
                    return firstIndex_ > lastIndex_;
                }

                @property size_t front()
                {
                    if (empty)
                    {
                        throw new RangeError();
                    }
                    return firstIndex_;
                }

                void popFront()
                {
                    if (empty)
                    {
                        throw new RangeError();
                    }
                    if (!Judy1Next(array_, &firstIndex_, NO_ERROR))
                    {
                        firstIndex_ = 1;
                        lastIndex_ = 0;
                    }
                }

                @property size_t back()
                {
                    if (empty)
                    {
                        throw new RangeError();
                    }
                    return lastIndex_;
                }

                void popBack()
                {
                    if (empty)
                    {
                        throw new RangeError();
                    }
                    if (!Judy1Prev(array_, &lastIndex_, NO_ERROR))
                    {
                        firstIndex_ = 1;
                        lastIndex_ = 0;
                    }
                }

                bool opIndex(const size_t index) const
                {
                    if (index < leftBound_ || index > rightBound_)
                    {
                        throw new RangeError();
                    }
                    return Judy1Test(array_, index, NO_ERROR) == 1;
                }

                size_t opDollar()
                {
                    return back;
                }

                @property Judy1ArrayRange save()
                {
                    return this;
                }

                @property auto count() const
                {
                    return Judy1Count(array_, leftBound_, rightBound_, NO_ERROR);
                }
        }
}


version(unittest)
{
    import std.algorithm;
    import std.exception;
    import std.stdio;
}

unittest
{
    writeln("[Judy1 UnitTest] - empty");

    auto array = Judy1Array();

    assert(array.empty, "Array starts empty");
    array[10] = false;
    assert(array.empty, "Unsetting bit still empty");
    array[5] = true;
    assert(!array.empty, "Setting bit no longer empty");
    array[5] = false;
    assert(array.empty, "Array ends empty");

    array[size_t.max] = true;
    assert(!array.empty);
}

unittest
{
    writeln("[Judy1 UnitTest] - count");

    auto array = Judy1Array();

    assert(array.count == 0, "Array counts starts at 0");

    array[0] = true;
    assert(array.count == 1, "Adding bit");
    array[1] = false;
    assert(array.count == 1, "Unset bit not included in count");
    array[1] = true;
    assert(array.count == 2);
    array[0] = false;
    array[1] = false;
    assert(array.count == 0, "Array count ends at 0");

    array[size_t.max] = true;
    assert(array.count == 1);
}

unittest
{
    writeln("[Judy1 UnitTest] - front and back");

    auto array = Judy1Array();

    assertThrown!RangeError(array.front, "Empty array");
    assertThrown!RangeError(array.back, "Empty array");

    array[2] = true;
    assert(array.front == 2);
    assert(array.back == 2);

    array[10] = true;
    assert(array.front == 2);
    assert(array.back == 10);

    array[5] = true;
    assert(array.front == 2);
    assert(array.back == 10);

    array[0] = true;
    assert(array.front == 0);
    assert(array.back == 10);

    array[10] = false;
    assert(array.front == 0);
    assert(array.back == 5);
}

unittest
{
    writeln("[Judy1 UnitTest] - popFront and popBack");

    auto array = Judy1Array();

    assertThrown!RangeError(array.popFront, "Empty array");
    assertThrown!RangeError(array.popBack, "Empty array");

    array[0] = true;
    array[1] = true;
    array[9] = true;
    array[10] = true;

    array.popFront();
    assert(array.front == 1);
    assert(array.back == 10);

    array.popBack();
    assert(array.front == 1);
    assert(array.back == 9);

    array.popFront();
    assert(array.front == 9);
    assert(array.back == 9);

    array.popBack();
    assert(array.empty);
}

unittest
{
    writeln("[Judy1 UnitTest] - opDollar");

    auto array = Judy1Array();

    assertThrown!RangeError(array[$]);

    array[0] = true;
    assert(array[$]);
    array[10] = true;
    assert(array[0..$].count == 2);
}

unittest
{
    writeln("[Judy1 UnitTest] - opIndex");

    auto array = Judy1Array();

    array[0] = true;
    array[3] = true;
    array[4] = true;
    array.set(5);

    assert(array[0]);
    assert(!array[1]);
    assert(!array[2]);
    assert(array[3]);
    assert(array[4]);
    assert(array[5]);
    assert(!array[6]);
}

unittest
{
    writeln("[Judy1 UnitTest] - set and unset");

    auto array = Judy1Array();

    array.set(0);
    assert(array[0]);
    array.unset(0);
    assert(!array[0]);

    array.set(size_t.max);
    assert(array[$]);
    array.unset(size_t.max);
    assert(!array[size_t.max]);
}

unittest
{
    writeln("[Judy1 UnitTest] - find in empty array");

    auto array = Judy1Array();

    size_t index = 0;
    assert(!array.first(index));
    assertThrown!RangeError(array.first());

    index = 0;
    assert(!array.next(index));

    index = -1;
    assert(!array.prev(index));

    index = -1;
    assert(!array.last(index));
    assertThrown!RangeError(array.last());
}

unittest
{
    writeln("[Judy1 UnitTest] - find in array with single bit at start");

    auto array = Judy1Array();
    array[0] = true;

    size_t index = 0;
    assert(array.first(index));
    assert(index == 0);
    assert(array.first() == 0);

    index = 0;
    assert(!array.next(index));

    index = 0;
    assert(!array.prev(index));

    index = 0;
    assert(array.last(index));
    assert(index == 0);

    index = -1;
    assert(array.prev(index));
    assert(index == 0);

    index = -1;
    assert(array.last(index));
    assert(index == 0);
    assert(array.last() == 0);
}

unittest
{
    writeln("[Judy1 UnitTest] - find in array with multiple in middle");

    auto array = Judy1Array();
    array[10] = true;
    array[11] = true;

    size_t index = 0;
    assert(array.first(index));
    assert(index == 10);
    assert(array.first() == 10);

    index = 0;
    assert(array.next(index));
    assert(index == 10);

    index = 0;
    assert(!array.prev(index));

    index = 0;
    assert(!array.last(index));



    index = 10;
    assert(array.first(index));
    assert(index == 10);

    index = 10;
    assert(array.next(index));
    assert(index == 11);

    index = 10;
    assert(!array.prev(index));

    index = 10;
    assert(array.last(index));
    assert(index == 10);



    index = 11;
    assert(array.first(index));
    assert(index == 11);

    index = 11;
    assert(!array.next(index));

    index = 11;
    assert(array.prev(index));
    assert(index == 10);

    index = 11;
    assert(array.last(index));
    assert(index == 11);



    index = -1;
    assert(array.prev(index));
    assert(index == 11);

    index = -1;
    assert(array.last(index));
    assert(index == 11);
    assert(array.last() == 11);
}

unittest
{
    writeln("[Judy1 UnitTest] - find in array with single bit at end");

    auto array = Judy1Array();
    auto END = size_t.max;
    array[size_t.max] = true;

    size_t index = 0;
    assert(array.first(index));
    assert(index == END);
    assert(array.first() == END);

    index = 0;
    assert(array.next(index));
    assert(index == END);

    index = 0;
    assert(!array.prev(index));

    index = 0;
    assert(!array.last(index));

    index = -1;
    assert(!array.prev(index));

    index = -1;
    assert(array.last(index));
    assert(index == END);
    assert(array.last() == END);
}

unittest
{
    writeln("[Judy1 UnitTest] - find empty in empty array");

    auto array = Judy1Array();

    size_t index = 0;
    assert(array.firstEmpty(index));
    assert(index == 0);

    assert(array.nextEmpty(index));
    assert(index == 1);

    index = 0;
    assert(!array.prevEmpty(index));
    
    index = 0;
    assert(array.lastEmpty(index));
    assert(index == 0);

    index = -1;
    assert(array.prevEmpty(index));
    assert(index == size_t.max - 1);

    index = -1;
    assert(array.lastEmpty(index));
    assert(index == size_t.max);
}

unittest
{
    writeln("[Judy1 UnitTest] - find empty with single element at start");

    auto array = Judy1Array();
    array[0] = true;

    size_t index = 0;
    assert(array.firstEmpty(index));
    assert(index == 1);

    index = 0;
    assert(array.nextEmpty(index));
    assert(index == 1);

    index = 0;
    assert(!array.prevEmpty(index));
    
    index = 0;
    assert(!array.lastEmpty(index));

    index = -1;
    assert(array.prevEmpty(index));
    assert(index == size_t.max - 1);

    index = -1;
    assert(array.lastEmpty(index));
    assert(index == size_t.max);
}

unittest
{
    writeln("[Judy1 UnitTest] - find empty with single element in middle");

    auto array = Judy1Array();
    array[10] = true;

    size_t index = 0;
    assert(array.firstEmpty(index));
    assert(index == 0);

    index = 0;
    assert(array.nextEmpty(index));
    assert(index == 1);

    index = 9;
    assert(array.firstEmpty(index));
    assert(index == 9);

    index = 9;
    assert(array.nextEmpty(index));
    assert(index == 11);

    index = 11;
    assert(array.prevEmpty(index));
    assert(index == 9);

    index = 11;
    assert(array.lastEmpty(index));
    assert(index == 11);
}

unittest
{
    writeln("[Judy1 UnitTest] - iteration");

    auto array = Judy1Array();
    auto setrange = iota(100, 1000, 10);

    foreach(ref index; array)
    {
        assert(false, "empty");
    }

    foreach(index; setrange)
    {
        array[index] = true;
    }

    size_t j = 0;
    foreach(ref index; array)
    {
        assert(index == setrange[j++]);
    }
    assert(j > 0);

    j = 0;
    foreach(ref index; array)
    {
        assert(index == setrange[j++]);
    }
    assert(j > 0);
}

unittest
{
    writeln("[Judy1 UnitTest] - free memory");

    Judy1Array* ptr;

    {
        auto array = Judy1Array();

        assert(array.memUsed == 0, "No memory used on empty array");
        assert(array.memActive == 0, "No memory active on empty array");

        auto testrange = iota(0, 100);

        // Set some bits
        foreach(index; testrange)
        {
            array[index] = true;
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
    writeln("[Judy1 UnitTest] - opSlice");

    auto array = Judy1Array();

    auto testrange = iota(0UL, 100UL);

    // Test empty
    foreach(index; array[])
    {
        assert(false, "Empty array");
    }

    // Test one bit
    array[0] = true;
    size_t j = 0;
    foreach(index; array[])
    {
        assert(index == j++);
    }
    assert(j == 1);
    array[0] = false;

    // Set some bits
    foreach(index; testrange)
    {
        array[index] = true;
    }


    assert(array.count == array[].count, "Array and slice length the same");

    j = 0;
    foreach(index; array[])
    {
        assert(index == testrange[j++]);
    }

    // backwards iteration
    j = testrange.length;
    foreach(index; retro(array[]))
    {
        assert(index == testrange[--j]);
    }

    auto slice = array[];
    array[7] = true;
    assert(slice[7]);
    array[7] = false;
    assert(!slice[7]);
}

unittest
{
    writeln("[Judy1 UnitTest] - opSlice[x..y]");

    auto array = Judy1Array();

    auto testrange = iota(0, 100);

    // Test empty
    foreach(index; array[1..2])
    {
        assert(false, "Empty array");
    }

    // Test one bit
    array[2] = true;
    size_t j = 0;
    foreach(index; array[0..5])
    {
        assert(index == 2);
        j++;
    }
    assert(j == 1);
    array[2] = false;
    
    // Insert some bits
    foreach(index; testrange)
    {
        array[index] = true;
    }

    j = 20;
    foreach(index; array[20..30])
    {
        assert(index == testrange[j++], "Indexed slice");
    }

    j = 25;
    foreach(index; array[25..500])
    {
        assert(index == testrange[j++], "Indexed slice beyond population");
    }

    j = 90;
    foreach(index; array[90..$])
    {
        assert(index == testrange[j++], "opDollar slice");
    }

    j = 20;
    foreach(index; retro(array[10..20]))
    {
        assert(index == testrange[j--], "Retrograde slice");
    }
    
    assertThrown!RangeError(array[10..20][9], "Out of bounds");
    assertThrown!RangeError(array[10..20][21], "Out of bounds");

    auto slice = array[10..20];
    array[12] = true;
    assert(slice[12]);
    array[12] = false;
    assert(!slice[12]);
}

