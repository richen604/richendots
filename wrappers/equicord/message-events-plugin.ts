/* Backported from Vencord bc68013. */
import { Devs } from "@utils/constants";
import definePlugin from "@utils/types";

export default definePlugin({
    name: "MessageEventsAPI",
    description: "Api required by anything using message events.",
    authors: [Devs.Arjix, Devs.hunt, Devs.Ven],
    patches: [
        {
            find: "#{intl::EDIT_TEXTAREA_HELP}",
            replacement: {
                match: /(?<=,channel:\i,message:\i\}\)\.then\().+?(?=\i\.content!==this\.props\.message\.content&&\i\((.+?)\)\})/,
                replace: (match, args) => "" +
                    `async ${match}` +
                    `if(await Vencord.Api.MessageEvents._handlePreEdit(${args}))` +
                    "return Promise.resolve({shouldClear:false,shouldRefocus:true});"
            }
        },
        {
            find: ".handleSendMessage,onResize:",
            replacement: {
                match: /(?<=channel:\i\}\)\.then\()(?:async )?(\i=>.+?let (\i)=\i\.\i\.parse\((\i),.+?\.getSendMessageOptions\(\{.+?\}\)?;)(?=.+?(\i)\.flags=)(?<=\)\((\{.+?\})\)\.then.+?)/,
                replace: (m, restCode, parsedMessage, channel, options, props) => "async " + restCode +
                    `if(await Vencord.Api.MessageEvents._handlePreSend(${channel}.id,${parsedMessage},${options},${props}))` +
                    "return{shouldClear:false,shouldRefocus:true};"
            }
        },
        {
            find: '("interactionUsernameProfile',
            replacement: {
                match: /let\{id:\i\}=(\i),\{id:\i\}=(\i);return \i\.useCallback\((\i)=>\{/,
                replace: (m, message, channel, event) =>
                    `const vcMsg=${message},vcChan=${channel};${m}Vencord.Api.MessageEvents._handleClick(vcMsg,vcChan,${event});`
            }
        }
    ]
});
