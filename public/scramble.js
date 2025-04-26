const CHARS = "abcdefghijklmnopqrstuvwxyzλλλ     ";

const getScrambled = (len) => {
    let scramble = '';
    for (let i = 0; i < len; i++) {
        const idx = Math.floor(Math.random() * CHARS.length);
        scramble += CHARS[idx];
    }
    return scramble;
};

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

class Scramble {
    constructor(elem, target) {
        this.elem = elem;
        this.target = target;
        this.upperBound = Math.round(0.7 * this.target.length);
        this.intervalId = null;
        this.totalSize = 0;
        this.correctPrefix = 0;
    }

    step = () => {
        if (this.totalSize == this.upperBound) {
            if (this.correctPrefix == this.target.length) {
                this.stop();
            } else {
                this.correctPrefix += 1;
                this.elem.innerHTML = (
                    this.target.substring(0, this.correctPrefix)
                    + "<span class=\"text-zinc-700\">"
                    + getScrambled(this.upperBound - this.correctPrefix)
                    + "</span>"
                    + "<span class=\"opacity-0\">"
                    + "l".repeat(this.target.length - Math.max(this.upperBound, this.correctPrefix))
                    + "</span>"
                );
            }
        } else {
            this.totalSize += 1;
            this.elem.innerHTML = (
                "<span class=\"text-zinc-700\">"
                + getScrambled(this.totalSize)
                + "</span>"
                + "<span class=\"opacity-0\">"
                + "l".repeat(this.target.length - this.totalSize)
                + "</span>"
            );
        }
    }

    start = () => {
        this.intervalId = setInterval(this.step, 20);
    }

    stop = () => {
        clearInterval(this.intervalId);
    }
}

class Fade {
    constructor(elem, target) {
        this.elem = elem;
        this.target = target;
    }

    start = () => {
        this.elem.style.opacity = 1;
    }
}
