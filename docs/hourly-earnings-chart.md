# Hourly earnings chart

The live Returns screen displays the `analytics` buckets from the existing hourly returns workspace response. Each bucket's `amount` is the sum of completed wallet return credits for that hour; `hourlyEarningRate` is a separate indicative rate and is not used to fill or replace chart values.

The chart sorts bucket timestamps chronologically, preserves zero values, and displays an empty state when no buckets are returned. The 1H, 6H, 12H, and 24H range controls appear only when the response contains enough hourly buckets. Summary totals and selected-point tooltips are calculated from the visible API buckets.

The chart is a Flutter custom painter with a one-shot line/area reveal, touch and drag selection, a crosshair, and an animated tooltip. It adds no chart package and does not change return calculation, accrual, wallet credit, or API behavior.
