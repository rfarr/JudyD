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
