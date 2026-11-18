import 'dart:js_interop';

@JS('history.state')
external JSAny? get _historyState;

@JS('history.replaceState')
external void _replaceState(JSAny? state, JSString title, JSString url);

void replaceRecoveryBrowserUrl(Uri url) =>
    _replaceState(_historyState, ''.toJS, url.toString().toJS);
