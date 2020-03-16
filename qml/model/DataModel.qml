import QtQuick 2.0
import Felgo 3.0

Item {

    // property to configure target dispatcher / logic
    property alias dispatcher: logicConnection.target

    // whether api is busy (ongoing network requests)
    readonly property bool isBusy: api.busy

    // whether a user is logged in
    readonly property bool userLoggedIn: _.userLoggedIn

    // model data properties
    readonly property alias publicRepos: _.publicRepos
    readonly property alias todoDetails: _.todoDetails

    // action success signals
    signal todoStored(var todo)

    // action error signals
    signal fetchTodosFailed(var error)
    signal fetchTodoDetailsFailed(int id, var error)
    signal storeTodoFailed(var todo, var error)

    // listen to actions from dispatcher
    Connections {
        id: logicConnection

        onFetchPublicRepos: {
            fetchDelay.search = search
            fetchDelay.searchChanged = true

            var cached = cache.getValue("public_repos")
            if(cached)
                _.publicRepos = cached

            if (!fetchDelay.running) {
                _.getPublicRepos(search)
                fetchDelay.searchChanged = false
            }
            fetchDelay.start();
        }

        // action 2 - fetchTodoDetails
        onFetchTodoDetails: {
            // check cached todo details first
            var cached = cache.getValue("todo_"+id)
            if(cached) {
                _.todoDetails[id] = cached
                todoDetailsChanged() // signal change within model to update UI
            }

            // load from api
            api.getTodoById(id,
                            function(data) {
                                // cache data first
                                cache.setValue("todo_"+id, data)
                                _.todoDetails[id] = data
                                todoDetailsChanged()
                            },
                            function(error) {
                                // action failed if no cached data
                                if(!cached) {
                                    fetchTodoDetailsFailed(id, error)
                                }
                            })
        }

        // action 3 - storeTodo
        onStoreTodo: {
            // store with api
            api.addTodo(todo,
                        function(data) {
                            // NOTE: Dummy REST API always returns 201 as id of new todo
                            // To simulate a new todo, we set correct local id based on current model
                            data.id = _.todos.length + 1

                            // cache newly added item details
                            cache.setValue("todo_"+data.id, data)

                            // add new item to todos
                            _.todos.unshift(data)

                            // cache updated todo list
                            cache.setValue("todos", _.todos)
                            todosChanged()

                            todoStored(data)
                        },
                        function(error) {
                            storeTodoFailed(todo, error)
                        })
        }

        // action 4 - clearCache
        onClearCache: {
            cache.clearAll()
        }

        // action 5 - login
        onLogin: _.userLoggedIn = true

        // action 6 - logout
        onLogout: _.userLoggedIn = false
    }

    // you can place getter functions here that do not modify the data
    // pages trigger write operations through logic signals only

    // rest api for data access
    RestAPI {
        id: api
        maxRequestTimeout: 3000 // use max request timeout of 3 sec
    }

    // storage for caching
    Storage {
        id: cache
    }

    // private
    Item {
        id: _

        // data properties
        property var publicRepos: []  // Array
        property var todoDetails: ({}) // Map

        // auth
        property bool userLoggedIn: false

        function getPublicRepos(search) {
            api.getPublicRepos(
                        search,
                        function(data) {
                            // cache data before updating model property
                            cache.setValue("public_repos",
                                           search === "" ? data : data.items)
                            _.publicRepos = search === "" ? data : data.items
                        },
                        function(error) {
                            // action failed if no cached data
                            if(!cached)
                                fetchTodosFailed(error)
                        })
        }
    }

    Timer {
        property bool searchChanged: false
        property string search

        id: fetchDelay
        interval: 1000
        onTriggered: if (searchChanged) {
                         _.getPublicRepos(search)
                         searchChanged = false
                     }
    }
}
