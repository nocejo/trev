NAME
    trev.pl - carries out taskwarrior tasks reviewing

WARNING
    Watch your data! Make proper backups.
    Just a sketch -- Starting development -- No tested.
    Do not rely on documentation, whether source code comments, information
    in text files or diagrams.

DESCRIPTION
    trev tries to be sort of a mini-shell focusing on taskwarrior reviewing.

    This script reads a list of pending taskwarrior (http://taskwarrior.org/)
    tasks and presents them to the user one at a time, prompting for an
    action --among a restricted set of taskwarrior commands; this action (or
    none) is performed on the task, whereupon the script proceeds to the next
    task up to the end of the list.

    At the script prompt the user can also include the current into a set of
    selected tasks which is continously shown. Tasks into this set are marked
    by taskwarrior as active or with a certain tag chosen by the user.

    List comes from a system call to task, obeying then the user preferred
    settings for visibility, order, decoration...

DISCLAIMER OF WARRANTY
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.

trev.pl is released under the MIT license. For details check the LICENSE file.

