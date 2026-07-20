"""Last quarter's fitted linear demand system for Product A and Product B
(GMM on cost-shifter instruments; converged, standard checks passed).

    q_a = a - b*p_a + d*p_b
    q_b = a - b*p_b + d*p_a
"""
import json
import pathlib

PARAMS = json.loads((pathlib.Path(__file__).parent / "demand_params.json").read_text())


def predict_quantities(p_a, p_b, params=PARAMS):
    a, b, d = params["a"], params["b"], params["d"]
    q_a = a - b * p_a + d * p_b
    q_b = a - b * p_b + d * p_a
    return q_a, q_b
