/*
 *   Copyright 2012-2013 Aleix Quintana Alsius <kinta@communia.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2, or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.taskmanager 0.1 as TaskManager
/*Item {

    width: 1000
    height:50
    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: CompactRepresentation {}
}*/
Item {
    id: main

    Layout.minimumWidth: vertical ? units.iconSizes.small : row.implicitWidth + units.largeSpacing
    Layout.minimumHeight: vertical ? row.implicitHeight + units.smallSpacing : units.smallSpacing
    Layout.maximumHeight: vertical ? row.implicitHeight + units.smallSpacing : units.smallSpacing
    Layout.maximumWidth: vertical ? units.iconSizes.small : row.implicitWidth + units.largeSpacing

    Layout.preferredHeight: Layout.minimumHeight
    Layout.preferredWidth: Layout.minimumWidth
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    anchors.fill: parent
    property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical

    // Config
    property bool show_application_icon: plasmoid.configuration.showApplicationIcon
    property bool show_window_title: true
    property bool use_fixed_width: plasmoid.configuration.useFixedWidth
    property int textType: plasmoid.configuration.textType

    // Window properties
    property bool noWindowActive: true
    property bool currentWindowMaximized: false
    property bool isActiveWindowPinned: false
    property bool isActiveWindowMaximized: false

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled

        screenGeometry: plasmoid.screenGeometry

        onActiveTaskChanged: {
            activeWindowModel.sourceModel = tasksModel
            updateActiveWindowInfo()
        }
        onDataChanged: {
            updateActiveWindowInfo()
        }
    }

    // should return always one item
    PlasmaCore.SortFilterModel {
        id: activeWindowModel
        filterRole: 'IsActive'
        filterRegExp: 'true'
        sourceModel: tasksModel
        onDataChanged: {
            updateActiveWindowInfo()
        }
        onCountChanged: {
            updateActiveWindowInfo()
        }
    }

    function toggleMaximized() {
        tasksModel.requestToggleMaximized(tasksModel.activeTask);
    }

    function activeTask() {
        return activeWindowModel.get(0) || {}
    }
    function updateActiveWindowInfo() {
        appLabel.visible = activeWindowModel.count != 0
        var actTask = activeTask()
        //console.warn(actTask.AppName)
        noWindowActive = activeWindowModel.count === 0 || actTask.IsActive !== true
        currentWindowMaximized = !noWindowActive && actTask.IsMaximized === true
        isActiveWindowPinned = actTask.VirtualDesktop === -1;
        if (noWindowActive) {
            appLabel.text = plasmoid.configuration.noWindowText
            iconItem.source = "" //plasmoid.configuration.noWindowIcon
        } else {
            appLabel.text = textType === 1 ? actTask.AppName : replaceTitle(actTask.display)
            iconItem.source = actTask.decoration
        }
        if (use_fixed_width) {
            main.width = plasmoid.configuration.fixedWidth
            if (show_application_icon) {
                //appLabel.width = main.width - row.spacing - iconItem.width
                appLabel.width = plasmoid.configuration.fixedWidth - row.spacing - iconItem.width
            } else {
                appLabel.width = plasmoid.configuration.fixedWidth - row.spacing
            }
            appLabel.elide = Text.ElideRight
        } else {
            if (show_application_icon) {
                main.width = iconItem.width + row.spacing + appLabel.paintedWidth
            } else {
                main.width = appLabel.paintedWidth
            }
            appLabel.width = appLabel.paintedWidth
            appLabel.elide = Text.ElideNone
        }
    }
    function replaceTitle(title) {
        if (!plasmoid.configuration.useWindowTitleReplace) {
            return title
        }
        return title.replace(new RegExp(plasmoid.configuration.replaceTextRegex), plasmoid.configuration.replaceTextReplacement);
    }

    Row {
        id: row
        spacing: 0
        anchors.centerIn: parent

        PlasmaCore.IconItem {
            id: iconItem
            height: appLabel.paintedHeight
            width: height + units.largeSpacing
            visible: show_application_icon
            anchors.verticalCenter: appLabel.verticalCenter
        }

        PlasmaComponents.Label {
            id: appLabel
            text: ""
            font.weight: plasmoid.configuration.bold?Font.Bold:Font.Medium
            font.capitalization: Font.Capitalize
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onDoubleClicked: {
            if (mouse.button == Qt.LeftButton) {
                toggleMaximized()
            }
        }
    }
}
