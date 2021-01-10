package com.gigateam.netagram;

/**
 * ...
 * @author Tiger
 */
class RollingIndex {
	public var index:UInt = 0;

	private var _max:UInt = 0;

	public function new(maximum:UInt) {
		_max = maximum;
	}

	public function greaterThan(right:UInt):Int {
		var diff:Int = (index % _max) - (right % _max);
		return diff;
	}

	public function leftGreater(left:UInt, right:UInt):Int {
		var diff:Int = (left % _max) - (right % _max);
		return diff;
	}

	public function leftAdd(src:UInt, target:Int):UInt {
		var diff:Int = (src + target) % _max;
		if (diff < 0) {
			diff += _max;
		}
		return diff;
	}

	public function add(target:Int):UInt {
		index = leftAdd(index, target);
		return index;
	}

	public static function fromMax(uint:UInt):RollingIndex {
		var ir:RollingIndex = new RollingIndex(uint);
		return ir;
	}

	public function clone():RollingIndex {
		var rollingIndex:RollingIndex = RollingIndex.fromMax(_max);
		rollingIndex.index = index;
		return rollingIndex;
	}
}
