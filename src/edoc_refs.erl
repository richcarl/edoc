%% =====================================================================
%% Licensed under the Apache License, Version 2.0 (the "License"); you may
%% not use this file except in compliance with the License. You may obtain
%% a copy of the License at <http://www.apache.org/licenses/LICENSE-2.0>
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%
%% Alternatively, you may use this file under the terms of the GNU Lesser
%% General Public License (the "LGPL") as published by the Free Software
%% Foundation; either version 2.1, or (at your option) any later version.
%% If you wish to allow use of your version of this file only under the
%% terms of the LGPL, you should delete the provisions above and replace
%% them with the notice and other provisions required by the LGPL; see
%% <http://www.gnu.org/licenses/>. If you do not delete the provisions
%% above, a recipient may use your version of this file under the terms of
%% either the Apache License or the LGPL.
%%
%% @private
%% @copyright 2003 Richard Carlsson
%% @author Richard Carlsson <carlsson.richard@gmail.com>
%% @see edoc
%% @see edoc_parse_ref
%% @end
%% =====================================================================

%% @doc Representation and handling of EDoc object references. See
%% {@link edoc_parse_ref} for more details.

-module(edoc_refs).

-export([app/1, app/2, package/1, module/1, module/2, module/3,
	 function/2, function/3, function/4, type/1, type/2, type/3,
	 to_string/1, to_label/1, get_uri/2, is_top/2,
	 relative_module_path/2, relative_package_path/2]).

-import(edoc_lib, [join_uri/2, escape_uri/1]).

-include("edoc.hrl").

-define(INDEX_FILE, "index.html").


%% Creating references:

app(App) ->
    {app, App}.

app(App, Ref) ->
    {app, App, Ref}.

module(M) ->
    {module, M}.

module(M, Ref) ->
    {module, M, Ref}.

module(App, M, Ref) ->
    app(App, module(M, Ref)).

package(P) ->
    {package, P}.

function(F, A) ->
    {function, F, A}.

function(M, F, A) ->
    module(M, function(F, A)).

function(App, M, F, A) ->
    module(App, M, function(F, A)).

type(T) ->
    {type, T}.

type(M, T) ->
    module(M, type(T)).

type(App, M, T) ->
    module(App, M, type(T)).


%% Creating a print string for a reference

to_string({app, A}) ->
    "//" ++ atom_to_list(A);
to_string({app, A, Ref}) ->
    "//" ++ atom_to_list(A) ++ "/" ++ to_string(Ref);
to_string({module, M}) ->
    atom_to_list(M) ;
to_string({module, M, Ref}) ->
    atom_to_list(M) ++ ":" ++ to_string(Ref);
to_string({package, P}) ->
    atom_to_list(P) ++ ".*";
to_string({function, F, A}) ->
    atom_to_list(F) ++ "/" ++ integer_to_list(A);
to_string({type, T}) ->
    atom_to_list(T) ++ "()".


%% Creating URIs and anchors.

to_label({function, F, A}) ->
    escape_uri(atom_to_list(F)) ++ "-" ++ integer_to_list(A);
to_label({type, T}) ->
    "type-" ++ escape_uri(atom_to_list(T)).

get_uri({app, App}, Env) ->
    join_uri(app_ref(App, Env), ?INDEX_FILE);
get_uri({app, App, Ref}, Env) ->
    app_ref(App, Ref, Env);
get_uri({module, M, Ref}, Env) ->
    module_ref(M, Env) ++ "#" ++ to_label(Ref);
get_uri({module, M}, Env) ->
    module_ref(M, Env);
get_uri({package, P}, Env) ->
    package_ref(P, Env);
get_uri(Ref, _Env) ->
    "#" ++ to_label(Ref).

abs_uri({module, M}, Env) ->
    module_absref(M, Env);
abs_uri({module, M, Ref}, Env) ->
    module_absref(M, Env) ++ "#" ++ to_label(Ref);
abs_uri({package, P}, Env) ->
    package_absref(P, Env).

module_ref(M, Env) ->
    case (Env#env.modules)(M) of
	"" ->
	    File = atom_to_list(M) ++ Env#env.file_suffix,
	    Path = relative_module_path(M, Env#env.package),
	    join_uri(Path, escape_uri(File));
	Base ->
	    join_uri(Base, module_absref(M, Env))
    end.

module_absref(M, Env) ->
    escape_uri(atom_to_list(M)) ++ escape_uri(Env#env.file_suffix).

package_ref(P, Env) ->
    case (Env#env.packages)(P) of
	"" ->
	    join_uri(relative_package_path(P, Env#env.package),
		     escape_uri(Env#env.package_summary));
	Base ->
	    join_uri(Base, package_absref(P, Env))
    end.

package_absref(P, Env) ->
    join_uri(escape_uri(atom_to_list(P)),
	     escape_uri(Env#env.package_summary)).

app_ref(A, Env) ->
    case (Env#env.apps)(A) of
	"" ->
	    join_uri(Env#env.app_default,
		     join_uri(escape_uri(atom_to_list(A)), ?EDOC_DIR));
	Base ->
	    Base
    end.

app_ref(A, Ref, Env) ->
    join_uri(app_ref(A, Env), abs_uri(Ref, Env)).

is_top({app, _App}, _Env) ->
    true;
is_top(_Ref, _Env) ->
    false.

%% Each segment of a path must be separately escaped before joining.

join_segments([S]) ->
    escape_uri(S);
join_segments([S | Ss]) ->
    join_uri(escape_uri(S), join_segments(Ss)).

%% 'From' is always the "current package" here:

%% The empty string is returned if the To module has only one segment,
%% implying a local reference.

relative_module_path(_To, _From) ->
    "".

relative_package_path(To, From) ->
    relative_path([atom_to_list(To)], [atom_to_list(From)]).

%% This takes two lists of path segments (From, To). Note that an empty
%% string will be returned if the paths are the same. Empty leading
%% segments are stripped from both paths.

relative_path(Ts, ["" | Fs]) ->
    relative_path(Ts, Fs);
relative_path(["" | Ts], Fs) ->
    relative_path(Ts, Fs);
relative_path(Ts, Fs) ->
    relative_path_1(Ts, Fs).

relative_path_1([T | Ts], [F | Fs]) when F == T ->
    relative_path_1(Ts, Fs);
relative_path_1(Ts, Fs) ->
    relative_path_2(Fs, Ts).

relative_path_2([_F | Fs], Ts) ->
    relative_path_2(Fs, [".." | Ts]);
relative_path_2([], []) ->
    "";
relative_path_2([], Ts) ->
    join_segments(Ts).
