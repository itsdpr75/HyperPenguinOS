#include <cstring>
#include <cstdlib>
#include <iostream>
#include <vector>
#include <string>

// Backend simplificado para operaciones BTRFS
// Se comunica con el KCM a través de la salida estándar

struct Snapshot {
    std::string id;
    std::string path;
    std::string date;
};

std::vector<Snapshot> listSnapshots() {
    std::vector<Snapshot> snapshots;
    FILE *fp = popen("btrfs subvolume list -s / 2>/dev/null", "r");
    if (!fp) return snapshots;

    char buf[512];
    while (fgets(buf, sizeof(buf), fp)) {
        Snapshot snap;
        // Parse simple: ID 256 gen 17 top level 5 path @snapshots/2026-07-04
        char id[64], path[256];
        if (sscanf(buf, "ID %s gen %*s top level %*s path %255s", id, path) == 2) {
            snap.id = id;
            snap.path = path;
            snapshots.push_back(snap);
        }
    }
    pclose(fp);
    return snapshots;
}

bool restoreSnapshot(const std::string &path) {
    std::string cmd = "btrfs subvolume snapshot " + path + " /@rootfs 2>/dev/null";
    return system(cmd.c_str()) == 0;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: rollback_backend <list|restore> [snapshot-path]" << std::endl;
        return 1;
    }

    if (strcmp(argv[1], "list") == 0) {
        auto snapshots = listSnapshots();
        for (const auto &s : snapshots) {
            std::cout << s.id << " " << s.path << std::endl;
        }
    } else if (strcmp(argv[1], "restore") == 0) {
        if (argc < 3) {
            std::cerr << "Snapshot path required" << std::endl;
            return 1;
        }
        return restoreSnapshot(argv[2]) ? 0 : 1;
    }

    return 0;
}
