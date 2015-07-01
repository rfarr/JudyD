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
    foreach(index; array[0..5]) // note last index is inclusive
    {
        writeln(index); // 3, 5
    }

    // Searching
    size_t index = 0;
    assert(array.next(index) && index == 3); // returns True if found and sets index
    assert(array.next(index) && index == 5);
    assert(array.next(index) && index == 123456789);
    assert(!array.next(index)); // not found

    index = 5;
    assert(array.prev(index) && index == 3); // find prev slot

    assert(array.nextEmpty(index) && index == 4); // find next empty slot
}
