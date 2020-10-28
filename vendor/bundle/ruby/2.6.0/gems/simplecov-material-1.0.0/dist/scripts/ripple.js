
import {MDCRipple} from '@material/ripple';

const buttons = document.querySelectorAll('.mdc-button');
const listItems = document.querySelectorAll('.mdc-list-item');
const iconButtons = document.querySelectorAll('.mdc-icon-button');

for (var b = 0; b < buttons.length; b++) {
  new MDCRipple.attachTo(buttons[b]);
}

for (var l = 0; l < listItems.length; l++) {
  new MDCRipple.attachTo(listItems[l]);
}

for (var i = 0; i < iconButtons.length; i++) {
  new MDCRipple.attachTo(iconButtons[i]);
}
