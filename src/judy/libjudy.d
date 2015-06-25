module judy.libjudy;

// Interface to C implementation of libjudy
extern(C)
{
    enum Errno
    {
        JU_ERRNO_NONE           = 0,
        JU_ERRNO_FULL           = 1,
        JU_ERRNO_NFMAX          = JU_ERRNO_FULL,
        JU_ERRNO_NOMEM          = 2,
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

    Error* NO_ERROR = null;
}

//JudyL
extern(C)
{
    // Retrieve pointer to address of element at index
    void** JudyLGet(const void* array, size_t index, Error* err) nothrow @nogc;

    // Insert and retrieve pointer to address of element at index
    void** JudyLIns(void** array, size_t index, Error* err) nothrow @nogc;
    int JudyLInsArray(void** array, size_t count, const size_t* index, const size_t* value) nothrow @nogc;

    // Remove element at index, return 1 if successful, 0 if Index not present,
    // error otherwise
    int JudyLDel(void** array, size_t index, Error* err) nothrow @nogc;

    // Count number of elements between index1 and index2 inclusively
    size_t JudyLCount(const void* array, size_t index1, size_t index2, Error* err) nothrow @nogc;
    // Find the index of the nth element of the array
    void** JudyLByCount(const void* array, size_t nth, size_t* index, Error* err) nothrow @nogc;

    size_t JudyLFreeArray(void** array, Error* err) nothrow @nogc;
    size_t JudyLMemUsed(const void* array) nothrow @nogc;
    size_t JudyLMemActive(const void* array) nothrow @nogc;

    void** JudyLFirst(const void* array, size_t* index, Error* err) nothrow @nogc;
    void** JudyLNext(const void* array, size_t* index, Error* err) nothrow @nogc;
    void** JudyLLast(const void* array, size_t* index, Error* err) nothrow @nogc;
    void** JudyLPrev(const void* array, size_t* index, Error* err) nothrow @nogc;

    int JudyLFirstEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
    int JudyLNextEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
    int JudyLLastEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
    int JudyLPrevEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
}

//Judy1
extern(C)
{
    int Judy1Test(const void* array, size_t index, Error* err) nothrow @nogc;
    int Judy1Set(void** array, size_t index, Error* err) nothrow @nogc;
    int Judy1SetArray(void** array, size_t cound, const size_t* index, Error* err) nothrow @nogc;
    
    int Judy1Unset(void** array, size_t index, Error* err) nothrow @nogc;
    size_t Judy1Count(const void* array, size_t index1, size_t index2, Error* err) nothrow @nogc;
    int Judy1ByCount(const void* array, size_t count, size_t* index, Error* err) nothrow @nogc;

    size_t Judy1FreeArray(void** array, Error* err) nothrow @nogc;
    size_t Judy1MemUsed(const void* array) nothrow @nogc;
    size_t Judy1MemActive(const void* array) nothrow @nogc;
    
    int Judy1First(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1Next(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1Last(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1Prev(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1FirstEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1NextEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1LastEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
    int Judy1PrevEmpty(const void* array, size_t* index, Error* err) nothrow @nogc;
}
