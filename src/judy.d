module util.judy;

import std.array;
import std.conv;
import std.range;
import std.stdio;

extern(C)
{
    enum Errno
    {
        JU_ERRNO_NONE = 0,
        JU_ERRNO_FULL = 1,
        JU_ERRNO_NFMAX = JU_ERRNO_FULL,
        JU_ERRNO_NOMEM = 2,
        JU_ERRNO_NULLPPARRAY    = 3,
        JU_ERRNO_NONNULLPARRAY  = 10,
        JU_ERRNO_NULLPINDEX     = 4,
        JU_ERRNO_NULLPVALUE     = 11,
        JU_ERRNO_NOTJUDY1       = 5,
        JU_ERRNO_NOTJUDYL       = 6,
        JU_ERRNO_NOTJUDYSL      = 7,
        JU_ERRNO_UNSORTED       = 12,
        JU_ERRNO_OVERRUN        = 8,
        JU_ERRNO_CORRUPT        = 9,
    }

    struct Error
    {
        Errno errno;
        int errID;
        size_t reserved[4];
    }

    Error* PJE0 = null;

    // Retrieve pointer to address of element at index
    void** JudyLGet(const void* array, size_t index, Error* err);

    // Insert and retrieve pointer to address of element at index
    void** JudyLIns(void** array, size_t index, Error* err);
    int JudyLInsArray(void** array, size_t count, const size_t* index, const size_t* value);

    // Remove element at index, return 1 if successful, 0 if Index not present,
    // error otherwise
    int JudyLDel(void** array, size_t index, Error* err);

    // Count number of elements between index1 and index2 inclusively
    size_t JudyLCount(const void* array, size_t index1, size_t index2, Error* err);
    // Find the index of the nth element of the array
    void** JudyLByCount(const void* array, size_t nth, size_t* index, Error* err);

    size_t JudyLFreeArray(void** array, Error* err);
    size_t JudyLMemUsed(const void* array);
    size_t JudyLMemActive(const void* array);

    void** JudyLFirst(const void* array, size_t* index, Error* err);
    void** JudyLNext(const void* array, size_t* index, Error* err);
    void** JudyLLast(const void* array, size_t* index, Error* err);
    void** JudyLPrev(const void* array, size_t* index, Error* err);

    int JudyLFirstEmpty(const void* array, size_t* index, Error* err);
    int JudyLNextEmpty(const void* array, size_t* index, Error* err);
    int JudyLLasttEmpty(const void* array, size_t* index, Error* err);
    int JudyLPrevEmpty(const void* array, size_t* index, Error* err);
}

struct JudyArray(Value)
{
    public:

        Value* front()
        {
            size_t index = 0;
            Value** element = cast(Value**)JudyLFirst(array, &index, PJE0);

            if (element is null)
            {
                return null;
            }

            return *element;
        }

        Value* back()
        {
            size_t index = -1;
            Value** element = cast(Value**)JudyLLast(array, &index, PJE0);

            if (element is null)
            {
                return null;
            }

            return *element;
        }

        bool remove(const size_t index)
        {
            auto removed = JudyLDel(&array, index, PJE0);

            return removed == 1;
        }

        Value* opIndex(const size_t index) const
        body
        {
            auto element = cast(Value**)JudyLGet(array, index, PJE0);

            if (element is null)
            {
                return null;
            }

            return *element;
        }

        void opIndexAssign(Value* value, const size_t index)
        {
            auto element = cast(Value**)JudyLIns(&array, index, PJE0);

            *element = value;
        }

        @property size_t length() const
        {
            auto count = JudyLCount(array, 0, -1, PJE0);

            return count;
        }

    private:
        void* array;
}

unittest
{
    auto array = JudyArray!string();

    assert(array.length == 0);

    auto testrange = iota(100, 1000, 10);

    // Alocate storage for the string values on the stack
    string[int] strings = assocArray(
        zip(
            testrange,
            map!(a => to!string(a))(testrange).array
        )
    );

    // Insert some elements
    auto len = 1;
    foreach(i; testrange)
    {
        array[i] = &strings[i];
        assert(array.length == len++);
    }
    len--;

    // Verify front and back
    assert(*array.front() == "100");
    assert(*array.back() == "990");

    // Verify elements
    foreach(i; testrange)
    {
        assert(*array[i] == strings[i]);
    }

    // Remove front
    array.remove(100);
    assert(array[100] is null);
    assert(*array.front() == "110");
    assert(*array.back() == "990");
    assert(array.length == --len);

    // Remove back
    array.remove(990);
    assert(array[990] is null);
    assert(*array.front() == "110");
    assert(*array.back() == "980");
    assert(array.length == --len);

    // Remove middle
    array.remove(550);
    assert(array[550] is null);
    assert(*array.front() == "110");
    assert(*array.back() == "980");
    assert(array.length == --len);


}
