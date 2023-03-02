import { loveEvents } from 'core/love-events';
import { ColouredText } from 'love.graphics';

const IDE_URL = 'https://liko-12.github.io/LIKO-IDE/';

export enum OverlayState {
    DISCONNECTED = 'DISCONNECTED',
    CONNECTED = 'CONNECTED',
    HIDDEN = 'HIDDEN',
}

interface Dialog {
    title: string,
    subTitle: string | ColouredText,
}

const DISCONNECTED_DIALOG: Readonly<Dialog> = {
    title: 'Waiting for LIKO-IDE to connect',
    subTitle: [
        [0xF5 / 255, 0xF5 / 255, 0xF5 / 255, 1],
        'Open ',
        [0xFA / 255, 0xA2 / 255, 0x1B / 255, 1],
        IDE_URL,
        [0xF5 / 255, 0xF5 / 255, 0xF5 / 255, 1],
        '\nin your browser to get started',
    ],
};

const CONNECTED_DIALOG: Readonly<Dialog> = {
    title: 'LIKO-IDE connected',
    subTitle: [
        [0xF5 / 255, 0xF5 / 255, 0xF5 / 255, 1],
        'Press ',
        [0xFA / 255, 0xA2 / 255, 0x1B / 255, 1],
        '"Run Game"',
        [0xF5 / 255, 0xF5 / 255, 0xF5 / 255, 1],
        ' from the bottom bar\nto have your game playing.'
    ],
}

interface Point {
    x: number,
    y: number,
}

interface Rectangle extends Point {
    width: number,
    height: number,
}

function isInRectangle(x: number, y: number, rectangle: Rectangle) {
    return (
        rectangle.x <= x && x <= rectangle.x + rectangle.width &&
        rectangle.y <= y && y <= rectangle.y + rectangle.height
    );
}

/**
 * The logic for the UI displayed as an overlay over the LIKO-12 screen.
 * Responsible for displaying the status of the server.
 */
export class GameRuntimeServerOverlay {
    private activeDialog?: Dialog = DISCONNECTED_DIALOG;

    private readonly logoPosition: Point = { x: 0, y: 0 };
    private readonly titlePosition: Point = { x: 0, y: 0 };
    private readonly subTitlePosition: Point = { x: 0, y: 0 };

    private readonly linkArea: Rectangle = { x: 0, y: 0, width: 0, height: 0 };

    private readonly primaryFont = love.graphics.newFont('res/fonts/Roboto-Regular.ttf', 24);
    private readonly secondaryFont = love.graphics.newFont('res/fonts/Roboto-Regular.ttf', 16);
    private readonly noticeFont = love.graphics.newFont('res/fonts/Roboto-Regular.ttf', 12);

    private readonly normalCursor = love.mouse.getSystemCursor('arrow');
    private readonly linkCursor = love.mouse.getSystemCursor('hand');

    private readonly logoImage = love.graphics.newImage('res/icon.png');

    private linkHovered = false;

    constructor() {
        this.logoImage.setFilter('nearest', 'nearest');
        this.updateLayout();

        loveEvents.on('resize', () => this.updateLayout());
        loveEvents.on('draw', () => this.renderOverlay());
        loveEvents.on('mousemoved', () => this.updateCursor());
        loveEvents.on('mousepressed', (x: number, y: number, button: number) => this.onMousePressed(x, y, button));
    }

    setState(state: OverlayState): void {
        if (state === OverlayState.HIDDEN) this.activeDialog = undefined;
        else if (state === OverlayState.CONNECTED) this.activeDialog = CONNECTED_DIALOG;
        else if (state === OverlayState.DISCONNECTED) this.activeDialog = DISCONNECTED_DIALOG;
        else throw new Error(`Unsupported state: ${state}`);

        this.updateLayout();
        this.updateCursor();
    }

    private onMousePressed(x: number, y: number, button: number): void {
        if (button !== 1) return;
        if (isInRectangle(x, y, this.linkArea)) {
            love.system.openURL(IDE_URL);
        }
    }

    private updateCursor() {
        const [mouseX, mouseY] = love.mouse.getPosition();
        const hovered = isInRectangle(mouseX, mouseY, this.linkArea);

        if (hovered !== this.linkHovered) {
            love.mouse.setCursor(hovered ? this.linkCursor : this.normalCursor);
        }

        this.linkHovered = hovered;
    }

    private updateLayout() {
        if (!this.activeDialog) return;
        const [windowWidth, windowHeight] = love.graphics.getDimensions();
        const anchorX = windowWidth * .5, anchorY = windowHeight * .5 + 70;

        this.logoPosition.x = anchorX;
        this.logoPosition.y = anchorY - 100;

        const primaryFontHeight = this.primaryFont.getHeight();
        const secondaryFontHeight = this.secondaryFont.getHeight();

        const titleWidth = this.primaryFont.getWidth(this.activeDialog.title);

        this.titlePosition.x = anchorX - titleWidth * .5;
        this.titlePosition.y = anchorY - primaryFontHeight;

        this.subTitlePosition.y = anchorY + secondaryFontHeight * .25;

        if (this.activeDialog === DISCONNECTED_DIALOG) {
            const openSegmentWidth = this.secondaryFont.getWidth('Open ');
            const linkSegmentWidth = this.secondaryFont.getWidth(IDE_URL);

            this.subTitlePosition.x = anchorX - (openSegmentWidth + linkSegmentWidth) * .5;

            this.linkArea.x = this.subTitlePosition.x + openSegmentWidth;
            this.linkArea.y = this.subTitlePosition.y;
            this.linkArea.width = linkSegmentWidth;
            this.linkArea.height = secondaryFontHeight;
        } else {
            this.subTitlePosition.x = 0;

            this.linkArea.x = -1;
            this.linkArea.y = -1;
            this.linkArea.width = 0;
            this.linkArea.height = 0;
        }
    }

    private renderOverlay() {
        if (!this.activeDialog) return;
        const [windowWidth, windowHeight] = love.graphics.getDimensions();

        love.graphics.setColor(0x0A / 255, 0x0A / 255, 0x0A / 255, 1);
        love.graphics.rectangle('fill', 0, 0, windowWidth, windowHeight);

        love.graphics.setColor(1, 1, 1, 1);
        love.graphics.draw(this.logoImage, this.logoPosition.x, this.logoPosition.y, 0, 7, 7, 8, 8);

        love.graphics.setColor(1, 1, 1, 1);

        love.graphics.setFont(this.primaryFont);
        love.graphics.printf(this.activeDialog.title, 0, this.titlePosition.y, windowWidth, 'center');

        love.graphics.setFont(this.secondaryFont);
        love.graphics.printf(this.activeDialog.subTitle, 0, this.subTitlePosition.y, windowWidth, 'center');

        love.graphics.setColor(0xFA / 255, 0xA2 / 255, 0x1B / 255, 1);
        love.graphics.rectangle('fill',
            this.linkArea.x, this.linkArea.y + this.linkArea.height - 3,
            this.linkArea.width - 1, 1);

        love.graphics.setColor(1, .2, .2, 1);
        love.graphics.setFont(this.noticeFont);
        love.graphics.printf(
            'Experimental release: always backup your code, expect breaking changes and instability.',
            7, windowHeight - 20, windowWidth - 20, 'left');
    }
}