/**
 * Calculate percentage change between two values.
 * @param {number|null} current
 * @param {number|null} prev
 * @returns {number|null}
 */
export function pctChange(current, prev) {
    if (current == null || prev == null || prev == 0) return null;
    return (current - prev) / prev;
}
