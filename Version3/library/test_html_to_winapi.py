import unittest
import os
import json
from bs4 import BeautifulSoup

# Import functions from html_to_winapi.py
from Version3.library.winapi_utils import load_registry, save_registry, get_or_assign_id

class TestHtmlToWinapi(unittest.TestCase):
    def setUp(self):
        self.registry_file = 'test_winapi_id_registry.json'
        if os.path.exists(self.registry_file):
            os.remove(self.registry_file)
        self.registry = {}
        self.next_id = 101

    def tearDown(self):
        if os.path.exists(self.registry_file):
            os.remove(self.registry_file)

    def test_id_assignment(self):
        id1, next_id = get_or_assign_id(self.registry, 'input1', self.next_id)
        id2, next_id = get_or_assign_id(self.registry, 'input2', next_id)
        self.assertEqual(id1, 101)
        self.assertEqual(id2, 102)
        self.assertEqual(next_id, 103)

    def test_id_registry_persistence(self):
        id1, next_id = get_or_assign_id(self.registry, 'input1', self.next_id)
        save_registry(self.registry)
        loaded = load_registry()
        self.assertEqual(loaded['input1'], 101)

    def test_duplicate_id_detection(self):
        self.registry['input1'] = 101
        id1, next_id = get_or_assign_id(self.registry, 'input1', self.next_id)
        self.assertEqual(id1, 101)
        self.assertEqual(next_id, 101)

if __name__ == '__main__':
    unittest.main()
