const CHARS = "abcdefghijklmnopqrstuvwxyzλ";

const getScrambled = (len) => {
    let scramble = '';
    for (let i = 0; i < len; i++) {
        const idx = Math.floor(Math.random() * CHARS.length);
        scramble += `${CHARS[idx]}`;
    }
    return scramble;
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class Scramble {
    constructor(elem, target) {
        this.elem = elem;
        this.target = target;
        this.intervalId = null;
        this.totalSize = 0;
        this.correctPrefix = 0;
    }

    step = () => {
        if (this.totalSize == this.target.length) {
            if (this.correctPrefix == this.target.length) {
                this.stop();
            } else {
                this.correctPrefix += 1;
                this.elem.textContent = (
                    this.target.substring(0, this.correctPrefix)
                    + getScrambled(this.totalSize - this.correctPrefix)
                );
            }
        } else {
            this.totalSize += 1;
            this.elem.textContent = getScrambled(this.totalSize);
        }
    }

    start = () => {
        this.intervalId = setInterval(this.step, 20);
    }

    stop = () => {
        clearInterval(this.intervalId);
    }
}
