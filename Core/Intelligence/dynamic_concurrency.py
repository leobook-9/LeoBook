import math

class DynamicConcurrencyEngine:
    @staticmethod
    def get_level(P: int, V: float = 1.0) -> int:
        if P < 10: return 2
        if P < 50: return 4
        if P < 150: return 8
        base_c = 16 + int(4 * math.log2(P / 150))
        return min(base_c, 32)
        
    @classmethod
    def get_for_predictions(cls, num_matches: int) -> int:
        c = cls.get_level(num_matches)
        print(f"    [Concurrency] Dynamic Scaling -> Level {c} for {num_matches} matches")
        return c

    @classmethod
    def get_for_rl(cls, batch_size: int) -> int:
        c = max(1, cls.get_level(batch_size) // 2)
        print(f"    [Concurrency] RL Scaling -> Level {c} for batch {batch_size}")
        return c

if __name__ == '__main__':
    for p in [5, 30, 100, 200, 500, 1000]:
        DynamicConcurrencyEngine.get_for_predictions(p)
