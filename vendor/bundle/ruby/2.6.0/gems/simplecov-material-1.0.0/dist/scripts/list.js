import {MDCList} from '@material/list';

const lists = document.querySelectorAll('.mdc-list');

for (var i = 0; i < lists.length; i++) {
  const list = MDCList.attachTo(lists[i]);
  list.wrapFocus = true;
}
