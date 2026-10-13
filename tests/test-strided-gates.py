import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("gates", Path(__file__).with_name("strided-gates.py"))
gates = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gates)


def measurements():
    rows = {}
    for count in (16, 64, 256, 1024, 4096, 16384, 65536):
        modes = ("pointer", "copy", "view") if count in (1024, 65536) else ("pointer",)
        for mode in modes:
            for offset in (0, 1):
                for trial in range(5):
                    key = ("f32", "add", (-1, -1, -1, 1), count, mode, offset, trial)
                    rows[*key, "general"] = 100
                    rows[*key, "candidate"] = 80 if count >= 256 else 99
    return rows


class AdmissionTests(unittest.TestCase):
    def test_small_calls_do_not_inherit_large_call_gain(self):
        result = gates.admissions(measurements(), "candidate")
        self.assertEqual([(key, count) for key, count, *_ in result], [(158, 256)])

    def test_large_call_regression_rejects_layout(self):
        rows = measurements()
        rows["f32", "add", (-1, -1, -1, 1), 65536, "view", 1, 0, "candidate"] = 120
        rows["f32", "add", (-1, -1, -1, 1), 65536, "view", 1, 1, "candidate"] = 120
        self.assertEqual(gates.admissions(rows, "candidate"), [])

    def test_missing_pair_fails_closed(self):
        rows = measurements()
        rows.pop(next(key for key in rows if key[-1] == "candidate"))
        with self.assertRaisesRegex(ValueError, "missing candidate"):
            gates.admissions(rows, "candidate")

    def test_missing_access_case_fails_closed(self):
        rows = measurements()
        rows = {key: value for key, value in rows.items() if key[4] != "view"}
        with self.assertRaisesRegex(ValueError, "incomplete access"):
            gates.admissions(rows, "candidate")

    def test_missing_trial_fails_closed(self):
        rows = {key: value for key, value in measurements().items() if key[-2] != 4}
        with self.assertRaisesRegex(ValueError, "five distinct"):
            gates.admissions(rows, "candidate")


if __name__ == "__main__":
    unittest.main()
