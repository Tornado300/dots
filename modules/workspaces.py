from fabric.hyprland.widgets import Workspaces as OWorkspaces

class Workspaces(OWorkspaces):
    def __init__(
        self,
        workspace_range = [1, 10],
        buttons = None,
        buttons_factory = None,
        invert_scroll: bool = False,
        empty_scroll: bool = False,
        **kwargs,
    ):
        super().__init__(
            buttons=buttons,
            buttons_factory=buttons_factory,
            invert_scroll=invert_scroll,
            empty_scroll=empty_scroll,
            **kwargs
        )
        self.workspace_range = workspace_range

    def on_workspace(self, _, event):
        if len(event.data) > 2:
            return

        active_workspace = int(event.data[0])
        if active_workspace == self._active_workspace:
            return
        if active_workspace < self.workspace_range[0] or active_workspace > self.workspace_range[1]:
            return

        if self._active_workspace is not None and (
            old_btn := self._buttons.get(self._active_workspace)
        ):
            old_btn.active = False
        self._active_workspace = active_workspace
        if not (btn := self.lookup_or_bake_button(active_workspace)):
            return

        btn.urgent = False
        btn.active = True

        if btn in self._container.children:
            return
        return self.insert_button(btn)
