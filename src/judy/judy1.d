module judy.judy1;

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
            return length == 0;
        }



        @property size_t front() const
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = 0;
            Judy1First(array_, &index, NO_ERROR);
            return index;
        }

        void popFront()
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = 0;
            Judy1First(array_, &index, NO_ERROR);
            Judy1Unset(&array_, index, NO_ERROR);
        }



        @property size_t back() const
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = -1;
            Judy1Last(array_, &index, NO_ERROR);
            return index;
        }

        void popBack()
        in
        {
            assert(!empty);
        }
        body
        {
            size_t index = -1;
            Judy1Last(array_, &index, NO_ERROR);
            Judy1Unset(&array_, index, NO_ERROR);
        }



        @property Judy1ArrayRange save() const
        {
            return Judy1ArrayRange(array_);
        }



        auto opSlice() const
        {
            return Judy1ArrayRange(array_);
        }

        auto opSlice(const size_t start, const size_t end) const
        {
            return Judy1ArrayRange(array_, start, end);
        }

        /* Get the last index of the array */
        size_t opDollar() const
        {
            size_t index = -1;
            if (Judy1Last(array_, &index, NO_ERROR) != 1)
            {
                throw new RangeError();
            }
            return index;
        }

        bool set(const size_t index)
        {
            return Judy1Set(&array_, index, NO_ERROR) == 1;
        }

        bool unset(const size_t index)
        {
            return Judy1Unset(&array_, index, NO_ERROR) == 1;
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

        /* Returns number of elements in the Judy array */
        @property size_t length() const
        {
            return Judy1Count(array_, 0, -1, NO_ERROR);
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
                    firstIndex_ = firstIndex;
                    lastIndex_ = lastIndex;

                    if (
                        Judy1First(array_, &firstIndex_, NO_ERROR) != 1 ||
                        Judy1Last(array_, &lastIndex_, NO_ERROR) != 1
                    )
                    {
                        firstIndex_ = 0;
                        lastIndex_ = 0;
                    }

                }

                @property bool empty() const
                {
                    return firstIndex_ == lastIndex_;
                }

                @property size_t front()
                in
                {
                    assert(!empty);
                }
                body
                {
                    return firstIndex_;
                }

                void popFront()
                in
                {
                    assert(!empty);
                }
                body
                {
                    Judy1Next(array_, &firstIndex_, NO_ERROR);
                }

                @property size_t back()
                in
                {
                    assert(!empty);
                }
                body
                {
                    return lastIndex_;
                }

                void popBack()
                in
                {
                    assert(!empty);
                }
                body
                {
                    Judy1Prev(array_, &lastIndex_, NO_ERROR);
                }

                bool opIndex(const size_t index) const
                {
                    if (index < firstIndex_ || index > lastIndex_)
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

                @property auto length() const
                {
                    return Judy1Count(array_, firstIndex_, lastIndex_, NO_ERROR);
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
    writeln("[judy1 UnitTest] - basic set and unset");

    auto array = Judy1Array();

    assert(array.length == 0);

    auto setrange = iota(100, 1000, 10);
    auto unsetrange = iota(0, 1000).setDifference(setrange);

    foreach(index; array)
    {
        assert(false, "empty array");
    }

    foreach(index; 0..1000)
    {
        assert(!array[index]);
    }

    // Set some bits
    auto len = 0;
    foreach(index; setrange)
    {
        array[index] = true;
        assert(array.length == ++len);
    }

    // Check that other bits still unset
    foreach(index; unsetrange)
    {
        assert(!array[index]);
    }

    // Verify front and back
    assert(array.front == 100, "Front set");
    assert(array.back == 990, "Back set");

    // Verify elements by opIndex
    foreach(index; setrange)
    {
        assert(array[index]);
    }

    // Verify elements by inputRange
    size_t j = 0;
    foreach(index; array)
    {
        assert(index == setrange[j++]);
    }

    // Unset front
    array[100] = false;
    assert(!array[100]);
    assert(array.front == 110, "Front updated");
    assert(array.back == 990, "Back unchanged");
    assert(array.length == --len);

    // Unset back
    array[990] = false;
    assert(!array[990]);
    assert(array.front == 110, "Front unchanged");
    assert(array.back == 980, "Back updated");
    assert(array.length == --len);

    // Unset middle
    array[550] = false;
    assert(!array[550]);
    assert(array.front == 110, "Front unchanged");
    assert(array.back == 980, "Back unchanged");
    assert(array.length == --len);

    auto newrange = setrange.filter!(a => a != 100 && a != 550 && a != 990).array;

    // Verify bits by opIndex
    foreach(index; newrange)
    {
        assert(array[index]);
    }

    // Verify bits by inputRange
    j = 0;
    foreach(index; array)
    {
        assert(index == newrange[j++]);
    }
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
    writeln("[Judy1 UnitTest] - opSlice");

    auto array = Judy1Array();

    auto testrange = iota(0UL, 100UL);

    // Test empty
    foreach(index; array[])
    {
        assert(false, "Empty array");
    }

    // Test one element
    array[0] = true;
    size_t j = 0;
    foreach(index; array[])
    {
        assert(j++ == 0, "Called once");
        assert(index == 0);
    }
    array.unset(0);

    // Set some bits
    foreach(index; testrange)
    {
        array[index] = true;
    }


    assert(array.length == array[].length, "Array and slice length the same");

    j = 0;
    foreach(index; array[])
    {
        assert(index == testrange[j++]);
    }

    // backwards iteration
    j = array.length;
    foreach(index; retro(array[]))
    {
        assert(index == testrange[--j]);
    }
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
    array[0] = true;
    size_t j = 0;
    foreach(index; array[0..5])
    {
        assert(j++ == 0, "Called once");
        assert(index == 0);
    }
    
    // Insert some elements
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
}

unittest
{
    writeln("[Judy1 UnitTest] - opDollar");

    auto array = Judy1Array();

    auto testrange = iota(0, 100, 5);

    // Test empty
    assertThrown!RangeError(array[$] = true, "Out of bounds");

    // Test one
    array[0] = true;
    assert(array[$] == true);
    
    // Set some bits
    foreach(i; testrange)
    {
        array[i] = true;
    }

    array[$-1] = false;

    assert(array[94] == false);
}


