# Chapter media

Drop chapter media files here (mp4 / webm / gif / png / jpg), then set the `src`
in the chapter's `media` array in `index.html`, e.g.:

```js
media:[
  {type:'video', src:'assets/welcome.mp4', caption:'A short welcome from the team.'},
  {type:'anim',  src:'assets/board.mp4',   caption:'Moving a task across the board.'}, // autoplays, looped, muted
  {type:'image', src:'assets/notion.png',  caption:'The Notion workspace.'}
]
```

- `video` — player with controls (talking-head videos, guides)
- `anim` — looping autoplay animation, no controls (animated screens; mp4/webm or gif)
- `image` — static screenshot

While `src` is empty, a styled placeholder is shown.
