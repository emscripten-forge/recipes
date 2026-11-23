pkg rebuild -global;
pkg load datatypes;
t = table([1; 2], {'a'; 'b'});
assert(size(t), [2 2]);
c = categorical({'a', 'b', 'a'});
assert(numel(categories(c)), 2);
disp(keyHash('abc'));
