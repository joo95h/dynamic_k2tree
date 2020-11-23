#include <gtest/gtest.h>
#include <boost/algorithm/string.hpp>
#include <boost/algorithm/string/classification.hpp>
#include <string>
#include <vector>
//#include "../include/dktree/DKtree_background.hpp"
#include "../include/dktree/DKtree.hpp"
//#include "../include/dktree/DKtree_delay.hpp"
#include "../include/dktree/DKtree_delay_.hpp"

void split(const std::string &str, std::vector<std::string> &cont,
           const std::string &delims = " ") {
    boost::split(cont, str, boost::is_any_of(delims));
}

TEST(ReadTest, ReadFromDataset) {
    unsigned int n_vertices = 10000;
    std::ostringstream path;

    path << "datasets/" << n_vertices << "/" << n_vertices << ".tsv";
//    path << "datasets/uk-2007-05@100000/uk-2007-05@100000.tsv";
    ifstream test_case(path.str());
//    dynamic_ktree::DKtree <2> graph(n_vertices);
//    dynamic_ktree::DKtree_delay<2> graph(n_vertices);
//    dynamic_ktree::DKtree_background<2> graph(n_vertices);
    dynamic_ktree::DKtree_delay_munro<2> graph(n_vertices);
    vector<tuple<etype, etype>> edges;
    double i = 0;
    if (test_case.is_open()) {
        std::string line;
        vector<std::string> substrings;
        const std::string delims = " ";
        clock_t end_add = clock();

        while (getline(test_case, line)) {
            split(line, substrings, delims);

            etype x = (etype) stoi(substrings[1]);
            etype y = (etype) stoi(substrings[2]);
            if (substrings[0] == "a") {
                ++i;
                clock_t aux = clock();
                graph.add_edge(x, y);
                end_add += clock() - aux;
//                cout << "x:" << x << "    y:" << y << endl;
//                cout << "========================" << endl;
                ASSERT_TRUE(graph.contains(x, y));
                edges.emplace_back(tuple<etype, etype>(x, y));
            }
        }

//        std::stringstream ss;
//        graph.serialize(ss);
        cout << "TOTAL TIME " << (double) (end_add) / CLOCKS_PER_SEC / i << endl;

//        clock_t del = 0;
        auto edge_it = graph.edge_begin();
        int count = 0;
        for(auto edge : edges) {
            ++count;
            ++edge_it;
            if(edge_it == graph.edge_end())
                break;
//            etype  x = get<0>(edge);
//            etype  y = get<1>(edge);
//
//            cout << "x:" << x << "    y:" << y << endl;
//            ASSERT_TRUE(graph.contains(x,y));
//            clock_t aux = clock();
//            graph.del_edge(x, y);
//            del += clock() - aux;
//            ASSERT_FALSE(graph.contains(x,y));
        }
        assert(count == edges.size());
//        cout << "TOTAL TIME " << (float) (del) / CLOCKS_PER_SEC << endl;
//

    } else {
        cout << "Unable to open file";
        FAIL();
    }
}

//TEST(a, v) {
//    std::stringstream ss;
//    dynamic_ktree::DKtree < 2 > graph;
//    graph.load(ss, "./", false);
//
//    unsigned int n_vertices = 100000;
//    std::ostringstream path;
//    path << "datasets/" << n_vertices << "/" << n_vertices << ".tsv";
//    ifstream test_case(path.str());
//
//    clock_t start2 = 0;
//    vector<tuple<etype, etype>> edges;
//    if (test_case.is_open()) {
//        std::string line;
//        vector<std::string> substrings;
//        const std::string delims = " ";
//
//        while (getline(test_case, line)) {
//            split(line, substrings, delims);
//
//            etype x = (etype) stoi(substrings[1]);
//            etype y = (etype) stoi(substrings[2]);
//            if (substrings[0] == "a") {
//                clock_t aux2 = clock();
//                graph.del_edge(x, y);
//                start2 += clock() - aux2;
//                edges.emplace_back(tuple<etype,etype>(x,y));
//            }
//        }
//
//        for(auto item: edges) {
//            etype  x = get<0>(item);
//            etype  y = get<1>(item);
//            cout << "x:" << x << "  y:" << y << endl;
//            ASSERT_FALSE(graph.contains(x,y));
//        }
////        cout << "TOTAL TIME old delete" << (float) (start) / CLOCKS_PER_SEC << endl;
//        cout << "TOTAL TIME new delete" << (float) (start2) / CLOCKS_PER_SEC << endl;
//
//    }
//}

TEST(edge, iterator) {
    int runs = 1;
    string folder("../evaluation/serialized/10000");
    double final = 0;

    dynamic_ktree::DKtree<2> tree;
    std::ifstream ifs;
    tree.load(ifs, folder, false);

    for (int i = 0; i < runs; i++) {
        int arcs = 0;
        double sum = 0;
        double total = 0;
        for (auto edge = tree.edge_begin(); edge != edge.end();) {
            clock_t aux = clock();
            ++edge;
            clock_t add = clock() - aux;
            sum += add;
            total += add;
            arcs++;
        }
        sum /= arcs;
        final += sum / CLOCKS_PER_SEC;
    }
    cout << final / (double) runs << endl;
}

int main(int argc, char **argv) {
    testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}