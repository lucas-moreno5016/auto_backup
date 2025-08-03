#include <iostream>
#include <vector>
#include <filesystem>
#include <fstream>
#include <chrono>
#include <thread>

namespace fs = std::filesystem;

// load paths from input file
std::vector<std::pair<fs::path, fs::path>> load_paths(const std::string& input_file, const fs::path& backup_root) {

    std::cout << "Loading source paths..." << std::endl;
    std::vector<std::pair<fs::path, fs::path>> path_pairs;

    std::ifstream file(input_file);
    if (!file) {
        std::cerr << "Failed to open " << input_file << '\n';
        return path_pairs;
    }

    std::string line;
    while (std::getline(file, line)) {
        if (line.empty()) continue;

        fs::path src_path = fs::path(line);
        if (!fs::exists(src_path) || !fs::is_directory(src_path)) {
            std::cerr << "[Warning] Skipping invalid directory: " << src_path << '\n';
            continue;
        }

        fs::path dst_path = backup_root / src_path.filename();
        path_pairs.emplace_back(src_path, dst_path);
    }

    std::cout << "Loaded source paths" << std::endl;
    return path_pairs;
}

// Compare file size and last write time
bool should_copy(const fs::path& src, const fs::path& dst) {
    if (!fs::exists(dst)) return true;

    auto src_time = fs::last_write_time(src);
    auto dst_time = fs::last_write_time(dst);

    return fs::file_size(src) != fs::file_size(dst) || src_time > dst_time;
}

// Copy file using streams (can be optimized further)
void copy_file_2(const fs::path& src, const fs::path& dst) {
    try {
        fs::create_directories(dst.parent_path());
        fs::copy_file(src, dst, fs::copy_options::overwrite_existing);
        std::cout << "[Copied] " << src << " -> " << dst << '\n';
    } catch (const fs::filesystem_error& e) {
        std::cerr << "[Error] Failed to copy: " << e.what() << '\n';
    }
}

// Recursively sync source to destination
void sync_directory(const fs::path& src_root, const fs::path& dst_root) {
    if (!fs::exists(src_root) || !fs::is_directory(src_root)) {
        std::cerr << "Invalid source: " << src_root << '\n';
        return;
    }

    for (const auto& entry : fs::recursive_directory_iterator(src_root)) {
        if (!entry.is_regular_file()) continue;

        fs::path relative_path = fs::relative(entry.path(), src_root);
        fs::path dst_path = dst_root / relative_path;

        if (should_copy(entry.path(), dst_path)) {
            copy_file_2(entry.path(), dst_path);
        }
    }
}

int main() {
    // Example: list of phone directories to back up
    // std::vector<std::pair<fs::path, fs::path>> folders_to_sync = {
    //     {"/media/phone/DCIM", "/mnt/backup/phone/DCIM"},
    //     {"/media/phone/Documents", "/mnt/backup/phone/Documents"}
    // };

    // std::string src_path = "./test_dir\\\\test_1_2";
    // std::cout << src_path << " is file ? " << fs::is_directory(src_path) << std::endl;

    std::string input_file = "./input.txt";
    fs::path backup_root = "./backup";
    std::vector<std::pair<fs::path, fs::path>> folders_to_sync = load_paths(input_file, backup_root);

    for (const auto& [src, dst] : folders_to_sync) {
        std::cout << "Syncing " << src << " -> " << dst << '\n';
        sync_directory(src, dst);
    }

    return 0;

    std::cout << std::endl << std::endl;
}
