#include <google/protobuf/arena.h>
#include <google/protobuf/duration.pb.h>
#include <google/protobuf/util/time_util.h>
#include <cassert>
#include <iostream>
#include <string>

int main() {
    // 1. Allocate a Duration message on an Arena
    google::protobuf::Arena arena;
    auto* duration = google::protobuf::Arena::Create<
        google::protobuf::Duration>(&arena);

    // 2. Populate: 2.5 seconds = 2s + 500000000ns
    duration->set_seconds(2);
    duration->set_nanos(500000000);

    assert(duration->seconds() == 2);
    assert(duration->nanos() == 500000000);

    // 3. Serialize to string
    std::string serialized;
    assert(duration->SerializeToString(&serialized));
    assert(!serialized.empty());

    // 4. Deserialize from string
    google::protobuf::Duration parsed;
    assert(parsed.ParseFromString(serialized));
    assert(parsed.seconds() == 2);
    assert(parsed.nanos() == 500000000);

    // 5. Use TimeUtil for conversion
    auto ts = google::protobuf::util::TimeUtil::SecondsToDuration(42);
    assert(ts.seconds() == 42);
    assert(ts.nanos() == 0);

    // 6. Test the Duration descriptor
    const auto* desc = google::protobuf::Duration::descriptor();
    assert(desc != nullptr);
    assert(desc->full_name() == "google.protobuf.Duration");

    // 7. Test field access via reflection
    const auto* field = desc->FindFieldByName("seconds");
    assert(field != nullptr);
    assert(field->number() == 1);
    assert(field->cpp_type() == google::protobuf::FieldDescriptor::CPPTYPE_INT64);

    std::cout << "protobuf-cpp test passed: "
              << "arena=" << desc->name()
              << " fields=" << desc->field_count()
              << " (" << serialized.size() << " bytes)" << std::endl;
    return 0;
}
