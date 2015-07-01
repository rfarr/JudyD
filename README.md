## JudyD

D language bindings for the C implementation of [Judy Arrays](https://en.wikipedia.org/wiki/Judy_array), invented by Doug Baskins.  More information on Judy arrays and the C implementation available at http://judy.sourceforge.net/

Currently Judy1 and JudyL are implemented.  In the future support for JudySL and JudyHS may be added.

### Judy1 Usage

A Judy1 array is a sparse array of bits.  Judy1Array keeps track only of which bits are set.

```d
import std.stdio;

import judy.judy1;

void main()
{
    auto array = Judy1Array();

    // Assignment
    array[123456789] = true;
    array[3] = true;
    array[5] = true;

    // Count and empty
    assert(array.count == 3);
    assert(!array.empty);

    // Iteration
    foreach(index; array)
    {
        writeln(index); // 3, 5, 123456789
    }

    if (array[3])
    {
        writeln("Index 3 is set");
    }

    assert(array.front == 3);
    assert(array.back == 123456789);

    // Slicing
    foreach(index; array[0..10]) // note last index is inclusive
    {
        writeln(index); // 3, 5
    }

    // Searching
    size_t index = 0;
    assert(array.next(index) && index == 3); // returns True if found and sets index
    assert(array.next(index) && index == 5);
    assert(array.next(index) && index = 123456789);
    assert(!array.next(index)); // not found

    index = 5;
    assert(array.prev(index) && index == 3); // find prev slot

    assert(array.nextEmpty(index) && index == 4); // find next empty slot
}
```

### JudyL Usage

JudyL maps size_t to size_t.  In practice the mapped value is a pointer to an object on the heap but can also be a scalar.

Scalar example:

```d
import core.exception;
import std.exception;
import std.range;
import std.stdio;

import judy.judyl;

void main()
{
    auto array = JudyLArray!int();

    array[123] = 7;
    array[456] = 99;
    array[array[123] + array[456]] = array[456] * 2;

    assert(array[123] == 7);
    assert(array[456] == 99);
    assert(array[106] == 198);

    assert(array.count == 3);
    assert(!array.empty);

    // Iteration
    foreach(ref entry; array)
    {
        writeln(entry.index); // 106, 123, 456
        writeln(entry.value); // 198, 7, 99
    }

    foreach(ref entry; array[].retro())
    {
        writeln(entry.index); // 456, 123, 106
        writeln(entry.value); // 99, 7, 198
    }

    // Front and back
    assert(array.front.value == 7);
    assert(array.front.index == 123);

    assert(array.back.value == 99);
    assert(array.back.index == 456);

    // Slicing
    auto slice = array[50..200];
    assert(slice[123] == 7);
    assert(slice[106] == 198);
    assertThrown!RangeError(slice[456]); // out of slice range

    // Searching
    size_t index;
    assert(array.next(index) && index == 106);
    assert(array.next(index) && index == 123);
    assert(array.next(index) && index == 456);
    assert(!array.next(index));

    index = 456;
    assert(array.prev(index) && index == 123);
    assert(array.prevEmpty(index) && index == 122);

    array.remove(123);
    assert(array.count == 2);
}
```

Class example:

```d
class Foo
{
}

void main()
{
    auto array = JudyLArray!Foo();

    array[123] = new Foo();
}

```

Struct example:

```d
struct Bar
{
}

void main()
{
    auto array = JudyLArray!(Bar*)();

    array[123] = new Bar();
}
```

### Memory Considerations

Because the underlying libJudy is implemented in C, objects passed to JudyLArray may be garbage collected if the only reference to them is from within the libjudy structure (which exists in non GC space).  Thus by default whenever a non scalar is passed to JudyLArray (ie a class, struct pointer, scalar pointer) it will automatically call GC.addRoot to ensure that the memory will not be collected.  When an item is removed from JudyLArray the root will also be removed.

When a JudyLArray goes out of scope it will be freed, as well as removing GC roots for every item in the array.

If you are using malloced memory or your own allocator you can turn off the default GC behaviour by passing false as the second template parameter.  Note that your should then explicitly free your array contents as this memory may become unreachable and leak.

Arrays are not supported.  Note that dynamic and associative arrays may be moved when resized, causing the pointer in libjudy to become invalidated.

### Judy1 API

```d
// Returns if array is empty (ie no bits set)
@property bool empty() const nothrow @nogc

// Returns number of set bit in the Judy array
@property size_t count() const nothrow @nogc

// Get lowest index of set bit
@property size_t front() const

// Unset lowest set bit
void popFront()

// Get highest index of set bit
@property size_t back() const

// Unset highest set bit
void popBack()

// Create a (const) slice of the array
auto opSlice() const nothrow @nogc

// Create a (const) slice of the array from start to end
auto opSlice(const size_t start, const size_t end) const nothrow @nogc

// Returns highest set index
size_t opDollar() const

// Check if bit set at index
bool opIndex(const size_t index) const nothrow @nogc

// Set bit at index to value
void opIndexAssign(bool value, const size_t index) nothrow @nogc

// Set bit at index
bool set(const size_t index) nothrow @nogc

// Unset bit at index
bool unset(const size_t index) nothrow @nogc
        
// Find first set bit and place it in index. Return false if not found
bool first(ref size_t index) const nothrow @nogc

// Find index of first, throws RangeError if empty
size_t first() const

// Find next set bit from index, and place it in index. Return false if not found
bool next(ref size_t index) const nothrow @nogc

// Find prev set bit from index, and place it in index. Return false if not found
bool prev(ref size_t index) const nothrow @nogc

// Find last set bit and place it in index. Return false if not found
bool last(ref size_t index) const nothrow @nogc

// Get index of last, throws RangeError if empty
size_t last() const

// Find first unset bit and place into index. Return false if not found
bool firstEmpty(ref size_t index) const nothrow @nogc

// Find next unset bit from index and place into index. Return false if not found;
bool nextEmpty(ref size_t index) const nothrow @nogc

// Find prev unset bit from index and place into index. Return false if not found;
bool prevEmpty(ref size_t index) const nothrow @nogc

// Find last unset bit and place into index. Return false if not found
bool lastEmpty(ref size_t index) const nothrow @nogc

// Return total amount of memory used by the population and infrastructure
@property size_t memUsed() const nothrow @nogc

// Return total amount of memory used by the population
@property size_t memActive() const nothrow @nogc
```

### JudyL API

```d
// Is the array empty?
@property bool empty() const nothrow @nogc

// Returns number of elements in the Judy array
@property size_t count() const nothrow @nogc

// Returns the index and element of first entry. Throws range error if empty.
@property JudyLEntry front() const

// Removes first element. Throws RangeError if empty.
void popFront()

// Gets index and element of last entry. Throws RangeError if empty.
@property JudyLEntry back() const

// Removes last element. Throws RangeError if empty.
void popBack()

// Create a slice over the underlying Judy array
auto opSlice() inout nothrow @nogc

// Create a slice with given indices over the underlying Judy array
auto opSlice(const size_t start, const size_t end) inout nothrow @nogc

// Return highest index of element in array
size_t opDollar() const

// Get element at index
ElementType opIndex(const size_t index) const

// Assign element to index
void opIndexAssign(ElementType value, const size_t index)

// Add element at index
void add(const size_t index, ElementType value)

// Get element at. Return true if found. Places element into value.
bool at(const size_t index, out ElementType value) const nothrow @nogc

// Check if has element at index
bool has(const size_t index) const nothrow @nogc

// Find first element >= index. Returns true if found, sets index and element.
bool first(ref size_t index, out ElementType found) const nothrow @nogc

// Find first elem >= index. Returns true if found. Sets index.
bool first(ref size_t index) const nothrow @nogc

// Get index of first element. Throws RangeError if empty.
size_t first() const

// Find next element > index. Returns true if found. Sets index and element.
bool next(ref size_t index, out ElementType found) const nothrow @nogc

// Find next element > index. Returns true if found. Sets index.
bool next(ref size_t index) const nothrow @nogc

// Find prev element < index. Returns true if found. Sets index and element.
bool prev(ref size_t index, out ElementType found) const nothrow @nogc

// Find prev element < index. Returns true if found. Sets index
bool prev(ref size_t index) const nothrow @nogc

// Find last element <= index. Returns true if found. Sets index and element.
bool last(ref size_t index, out ElementType found) const nothrow @nogc

// Find last element <= index. Returns true if found. Sets index.
bool last(ref size_t index) const

// Get index of last element. Throws RangeError if empty.
size_t last() const

// Find first empty slot >= index. Returns true if found. Sets index.
bool firstEmpty(ref size_t index) const nothrow @nogc

// Find next empty slot > index. Returns true if found. Sets index.
bool nextEmpty(ref size_t index) const nothrow @nogc

// Find prev empty slot < index. Returns true if found. Sets index.
bool prevEmpty(ref size_t index) const nothrow @nogc

// Find last empty slot <= index. Returns true if found. Sets index.
bool lastEmpty(ref size_t index) const nothrow @nogc

// Gets total amount of memory used by population and infrastructure
@property size_t memUsed() const nothrow @nogc

// Gets total amount of memory used by population (pointers only)
@property size_t memActive() const nothrow @nogc

// An entry containing the index and element. Used for iteration
struct JudyLEntry
{
    // Get index of entry
    @property size_t index() const nothrow @nogc

    // Get value of entry
    @property ElementType value() nothrow @nogc
}
```
