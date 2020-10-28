import {MDCTopAppBar} from '@material/top-app-bar';
import {MDCDrawer} from '@material/drawer';

const drawer = MDCDrawer.attachTo(document.querySelector('.mdc-drawer'));
const topAppBar = MDCTopAppBar.attachTo(document.getElementById('app-bar'));

topAppBar.setScrollTarget(document.querySelector('.main-content'));
topAppBar.listen('MDCTopAppBar:nav', () => {
  drawer.open = !drawer.open;
});

function windowSizeChange() {
  if (window.innerWidth <= 1250) {
    drawer.open = false;
  } else {
    drawer.open = true;
  }
}

window.addEventListener('resize', windowSizeChange);
