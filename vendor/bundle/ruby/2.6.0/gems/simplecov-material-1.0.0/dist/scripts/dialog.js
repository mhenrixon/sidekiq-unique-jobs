import {MDCDialog} from '@material/dialog';

export function openModal(fileName) {
  const dialog = new MDCDialog(document.getElementById(fileName));
  dialog.open();
}

window.openModal = openModal;
