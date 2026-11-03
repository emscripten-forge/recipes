#include <cstdio>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <leveldb/db.h>
#include <leveldb/write_batch.h>

// assert() is compiled out in Release builds
#define CHECK(cond)                                                   \
    do {                                                              \
        if (!(cond)) {                                                \
            std::fprintf(stderr, "%s:%d: CHECK failed: %s\n",        \
                         __FILE__, __LINE__, #cond);                  \
            std::exit(1);                                             \
        }                                                             \
    } while (0)

static std::string key_of(int i) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "key%08d", i);
    return buf;
}

static std::string value_of(int i) {
    return std::string(1000, static_cast<char>('a' + i % 26)) + std::to_string(i);
}

int main() {
    const std::string dbname = "testdb";
    const int n = 5000;  // ~5 MB of values

    leveldb::Options options;
    options.create_if_missing = true;
    // a small memtable forces many flushes and level-0 compactions
    options.write_buffer_size = 64 * 1024;

    leveldb::DB* raw = nullptr;
    leveldb::Status status = leveldb::DB::Open(options, dbname, &raw);
    CHECK(status.ok());
    std::unique_ptr<leveldb::DB> db(raw);

    status = db->Put(leveldb::WriteOptions(), "hello", "world");
    CHECK(status.ok());
    std::string read_value;
    status = db->Get(leveldb::ReadOptions(), "hello", &read_value);
    CHECK(status.ok());
    CHECK(read_value == "world");

    for (int i = 0; i < n; ++i) {
        CHECK(db->Put(leveldb::WriteOptions(), key_of(i), value_of(i)).ok());
    }

    leveldb::WriteBatch batch;
    batch.Delete("hello");
    batch.Put("batch", "ok");
    CHECK(db->Write(leveldb::WriteOptions(), &batch).ok());

    db->CompactRange(nullptr, nullptr);
    db.reset();

    // reopen and read everything back from the sstables
    status = leveldb::DB::Open(options, dbname, &raw);
    CHECK(status.ok());
    db.reset(raw);

    CHECK(db->Get(leveldb::ReadOptions(), "hello", &read_value).IsNotFound());
    CHECK(db->Get(leveldb::ReadOptions(), "batch", &read_value).ok());
    CHECK(read_value == "ok");

    int count = 0;
    std::unique_ptr<leveldb::Iterator> it(db->NewIterator(leveldb::ReadOptions()));
    for (it->Seek("key"); it->Valid() && it->key().starts_with("key"); it->Next()) {
        CHECK(it->key().ToString() == key_of(count));
        CHECK(it->value().ToString() == value_of(count));
        ++count;
    }
    CHECK(it->status().ok());
    CHECK(count == n);
    it.reset();

    std::string files;
    CHECK(db->GetProperty("leveldb.num-files-at-level0", &files));
    std::cout << "level-0 files after compaction: " << files << std::endl;

    db.reset();
    std::cout << "LevelDB test passed!" << std::endl;
    return 0;
}
