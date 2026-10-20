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

    def test_dispatch_cannot_admit_an_unmeasured_layout(self):
        limits = gates.admissions(measurements(), "candidate")
        phantom = (159, 256, "f32", "add", (-1, -1, 0, 1))
        rows = {(*key[:-1], "dispatch" if key[-1] == "candidate" else key[-1]): value
                for key, value in measurements().items()}
        self.assertEqual(gates.validate_dispatch(rows, [phantom], limits), [])

    def test_below_gate_regression_rejects_operation(self):
        limits = gates.admissions(measurements(), "candidate")
        rows = {(*key[:-1], "dispatch" if key[-1] == "candidate" else key[-1]): value
                for key, value in measurements().items()}
        for key in list(rows):
            if key[3] == 16 and key[-1] == "dispatch":
                rows[key] = 120
        self.assertEqual(gates.validate_dispatch(rows, limits, limits), [])

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

    def dispatch_measurements(self):
        rows = {}
        for count in (16, 64, 256, 1024, 4096, 16384, 65536):
            modes = ("pointer", "view") if count < 256 else ("pointer", "copy", "view", "alias")
            for mode in modes:
                for offset in (0, 1):
                    for trial in range(5):
                        key = ("f32", "add", (-1, -1, -1, 1), count, mode, offset, trial)
                        rows[*key, "general"] = 100
                        rows[*key, "dispatch"] = 80 if count >= 256 else 100
        return rows

    def test_targeted_dispatch_validates_only_admitted_sizes(self):
        limits = [(158, 256, "f32", "add", (-1, -1, -1, 1))]
        rows = self.dispatch_measurements()
        accepted = gates.admissions(rows, "dispatch", limits)
        self.assertEqual(gates.validate_dispatch(rows, accepted, limits), limits)

    def test_targeted_dispatch_requires_below_threshold_controls(self):
        limits = [(158, 256, "f32", "add", (-1, -1, -1, 1))]
        rows = {key: value for key, value in self.dispatch_measurements().items() if key[3] != 64}
        with self.assertRaisesRegex(ValueError, "incomplete access"):
            gates.admissions(rows, "dispatch", limits)

    def test_targeted_dispatch_rejects_small_call_regression(self):
        limits = [(158, 256, "f32", "add", (-1, -1, -1, 1))]
        rows = self.dispatch_measurements()
        for key in rows:
            if key[3] == 16 and key[-1] == "dispatch":
                rows[key] = 120
        accepted = gates.admissions(rows, "dispatch", limits)
        self.assertEqual(gates.validate_dispatch(rows, accepted, limits), [])


if __name__ == "__main__":
    unittest.main()
