#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#include "tkrzw_dbm_hash.h"
#include "tkrzw_dbm_tree.h"

#define CHECK(cond)                                                          \
    do {                                                                     \
        if (!(cond)) {                                                       \
            std::fprintf(stderr, "line %d: CHECK failed: %s\n", __LINE__, #cond); \
            std::exit(1);                                                    \
        }                                                                    \
    } while (0)

using namespace tkrzw;

int main() {
    // hash database: set / get / remove, then reopen
    {
        HashDBM dbm;
        CHECK(dbm.Open("casket.tkh", true, File::OPEN_TRUNCATE) == Status::SUCCESS);
        for (int i = 0; i < 1000; ++i) {
            CHECK(dbm.Set("key" + std::to_string(i), "value" + std::to_string(i)) == Status::SUCCESS);
        }
        CHECK(dbm.Remove("key7") == Status::SUCCESS);
        CHECK(dbm.Close() == Status::SUCCESS);

        CHECK(dbm.Open("casket.tkh", false) == Status::SUCCESS);
        int64_t count = -1;
        CHECK(dbm.Count(&count) == Status::SUCCESS);
        CHECK(count == 999);
        std::string value;
        CHECK(dbm.Get("key42", &value) == Status::SUCCESS);
        CHECK(value == "value42");
        CHECK(dbm.Get("key7", &value) == Status::NOT_FOUND_ERROR);
        CHECK(dbm.Close() == Status::SUCCESS);
    }

    // tree database: keys come back in order
    {
        TreeDBM dbm;
        CHECK(dbm.Open("casket.tkt", true, File::OPEN_TRUNCATE) == Status::SUCCESS);
        CHECK(dbm.Set("banana", "2") == Status::SUCCESS);
        CHECK(dbm.Set("cherry", "3") == Status::SUCCESS);
        CHECK(dbm.Set("apple", "1") == Status::SUCCESS);

        std::vector<std::string> keys;
        auto iter = dbm.MakeIterator();
        CHECK(iter->First() == Status::SUCCESS);
        std::string key, value;
        while (iter->Get(&key, &value) == Status::SUCCESS) {
            keys.push_back(key);
            CHECK(iter->Next() == Status::SUCCESS);
        }
        CHECK((keys == std::vector<std::string>{"apple", "banana", "cherry"}));
        CHECK(dbm.Close() == Status::SUCCESS);
    }

    std::printf("tkrzw test passed\n");
    return 0;
}
