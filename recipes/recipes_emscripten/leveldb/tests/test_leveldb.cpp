#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>
#include <leveldb/db.h>

int main() {
    leveldb::DB* db;
    leveldb::Options options;
    options.create_if_missing = true;

    std::string dbname = "testdb";

    leveldb::Status status = leveldb::DB::Open(options, dbname, &db);
    assert(status.ok());

    std::string key = "hello";
    std::string value = "world";
    status = db->Put(leveldb::WriteOptions(), key, value);
    assert(status.ok());

    std::string read_value;
    status = db->Get(leveldb::ReadOptions(), key, &read_value);
    assert(status.ok());
    assert(read_value == value);

    delete db;

    std::cout << "LevelDB test passed!" << std::endl;
    return 0;
}
