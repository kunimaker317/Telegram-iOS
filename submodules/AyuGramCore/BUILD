load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "AyuGramCore",
    module_name = "AyuGramCore",
    srcs = glob([
        "Sources/**/*.swift",
    ]),
    copts = [
        "-warnings-as-errors",
    ],
    deps = [],
    sdk_frameworks = ["UserNotifications"],
    visibility = [
        "//visibility:public",
    ],
)
